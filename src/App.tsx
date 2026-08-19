import { useEffect, useMemo, useState } from 'react';
import { baseClubName, decades, overlapsDecade, players, regions, teams, type CareerStop, type Difficulty, type PlayerSeed } from './data';
import { fetchCareer } from './wiki';

type Filters={ difficulty:'all'|Difficulty; decade:string; team:string; region:string };
type Profile={ xp:number; coins:number; streak:number; bestStreak:number; correct:number; played:number; lastDaily?:string };
type Round={ seed:PlayerSeed; career:CareerStop[]; live:boolean; attempts:number; hints:number; resolved:boolean; won:boolean; guesses:string[]; daily:boolean };

const defaultProfile:Profile={xp:0,coins:100,streak:0,bestStreak:0,correct:0,played:0};
const tierDefs=[['Rookie',0,'🌱'],['Prospect',350,'🟢'],['Pro',900,'🔵'],['Star',1800,'⭐'],['World Class',3200,'🌍'],['Legend',5200,'👑']] as const;
const reward={easy:{xp:80,coins:15},medium:{xp:120,coins:22},hard:{xp:180,coins:30}};
const today=()=>new Date().toLocaleDateString('en-CA');
const norm=(s:string)=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]/g,'');

function currentTier(xp:number){
  let current=tierDefs[0];
  for(const tier of tierDefs) if(xp>=tier[1]) current=tier;
  const index=tierDefs.indexOf(current); const next=tierDefs[index+1];
  return {current,next,index};
}

function deterministicDaily(){
  const key=today().replace(/-/g,'');
  const n=key.split('').reduce((a,c)=>a+Number(c),0);
  return players[n%players.length];
}

export default function App(){
  const [profile,setProfile]=useState<Profile>(()=>{ try{return {...defaultProfile,...JSON.parse(localStorage.getItem('wikiball-profile')||'{}')}}catch{return defaultProfile} });
  const [filters,setFilters]=useState<Filters>({difficulty:'all',decade:'all',team:'all',region:'all'});
  const [round,setRound]=useState<Round|null>(null);
  const [guess,setGuess]=useState('');
  const [loading,setLoading]=useState(false);
  const [message,setMessage]=useState('');

  useEffect(()=>localStorage.setItem('wikiball-profile',JSON.stringify(profile)),[profile]);

  const pool=useMemo(()=>players.filter(p=>
    (filters.difficulty==='all'||p.difficulty===filters.difficulty)&&
    overlapsDecade(p,filters.decade)&&
    (filters.team==='all'||p.fallbackCareer.some(s=>baseClubName(s.club)===filters.team))&&
    (filters.region==='all'||p.region===filters.region)
  ),[filters]);

  const tier=currentTier(profile.xp);

  async function startRound(daily=false){
    const seed=daily?deterministicDaily():pool[Math.floor(Math.random()*pool.length)];
    if(!seed){setMessage('No players match that combination yet. Reset one or more filters.');return;}
    setLoading(true); setMessage(''); setGuess('');
    let career=seed.fallbackCareer, live=false;
    try{ career=await fetchCareer(seed.wikipediaTitle); live=true; }catch{ /* curated fallback */ }
    setRound({seed,career,live,attempts:3,hints:0,resolved:false,won:false,guesses:[],daily});
    setLoading(false);
  }

  function finish(won:boolean,nextGuesses:string[]){
    if(!round||round.resolved) return;
    const alreadyDaily=round.daily&&profile.lastDaily===today();
    const base=reward[round.seed.difficulty];
    const attemptMultiplier=Math.max(.55,1-(3-round.attempts)*.15);
    const streakBonus=won?Math.min(profile.streak,10)*5:0;
    const dailyBonus=round.daily&&!alreadyDaily&&won?50:0;
    const xp=won&&!alreadyDaily?Math.round(base.xp*attemptMultiplier+streakBonus+dailyBonus):0;
    const coins=won&&!alreadyDaily?base.coins+Math.min(profile.streak,8):0;
    const nextStreak=won?profile.streak+1:0;
    setProfile(p=>({...p,xp:p.xp+xp,coins:p.coins+coins,streak:nextStreak,bestStreak:Math.max(p.bestStreak,nextStreak),correct:p.correct+(won?1:0),played:p.played+1,lastDaily:round.daily?today():p.lastDaily}));
    setRound({...round,resolved:true,won,guesses:nextGuesses});
    setMessage(won?`Correct! +${xp} XP · +${coins} coins`:`It was ${round.seed.name}.`);
  }

  function submitGuess(e:React.FormEvent){
    e.preventDefault(); if(!round||round.resolved||!guess.trim()) return;
    const next=[...round.guesses,guess.trim()];
    const valid=[round.seed.name,...round.seed.aliases].some(name=>norm(name)===norm(guess));
    if(valid){finish(true,next);setGuess('');return;}
    if(round.attempts<=1){finish(false,next);setGuess('');return;}
    setRound({...round,attempts:round.attempts-1,guesses:next}); setMessage('Not that player — have another go.'); setGuess('');
  }

  function buyHint(){
    if(!round||round.resolved||round.hints>=3) return;
    if(profile.coins<20){setMessage('You need 20 coins for another hint.');return;}
    setProfile(p=>({...p,coins:p.coins-20})); setRound({...round,hints:round.hints+1}); setMessage('Hint unlocked for 20 coins.');
  }

  function resetFilters(){setFilters({difficulty:'all',decade:'all',team:'all',region:'all'});setMessage('');}

  if(round){
    const sourceUrl=`https://en.wikipedia.org/wiki/${encodeURIComponent(round.seed.wikipediaTitle.replace(/ /g,'_'))}`;
    return <main className="shell game-shell">
      <header className="topbar"><button className="brand button-reset" onClick={()=>{setRound(null);setMessage('')}}>WIKIBALL ⚽️</button><div className="wallet"><span>🔥 {profile.streak}</span><span>🪙 {profile.coins}</span><span>{tier.current[2]} {tier.current[0]}</span></div></header>
      <section className="game-head">
        <div><span className={`difficulty ${round.seed.difficulty}`}>{round.seed.difficulty}</span>{round.daily&&<span className="daily-pill">Daily</span>}</div>
        <div className="attempts">{Array.from({length:3},(_,i)=><span key={i} className={i<round.attempts?'alive':'used'}>⚽</span>)}</div>
      </section>
      <section className="career-card">
        <p className="eyebrow">WHO AM I?</p><h1>Guess the player from their career</h1>
        <div className="timeline">{round.career.map((stop,i)=><div className="stop" key={`${stop.years}-${stop.club}-${i}`}><div className="year">{stop.years}</div><div className="line"><span></span></div><div className="club">{stop.club}</div></div>)}</div>
        {!round.resolved&&<><div className="hint-row">
          {round.hints>=1&&<span>🌍 {round.seed.nationality}</span>}
          {round.hints>=2&&<span>📍 {round.seed.position}</span>}
          {round.hints>=3&&<span>🔤 Starts with “{round.seed.name[0]}”</span>}
        </div>
        <form className="guess-form" onSubmit={submitGuess}><input autoFocus value={guess} onChange={e=>setGuess(e.target.value)} placeholder="Type a player name…" aria-label="Player guess"/><button className="primary">Guess</button></form>
        <div className="actions"><button className="secondary" onClick={buyHint} disabled={round.hints>=3}>💡 Hint · 20</button><button className="ghost" onClick={()=>finish(false,round.guesses)}>Give up</button></div></>}
        {round.resolved&&<div className={`result ${round.won?'win':'lose'}`}><div className="result-icon">{round.won?'🎉':'🫣'}</div><h2>{round.seed.name}</h2><p>{round.seed.nationality} · {round.seed.position}</p><a href={sourceUrl} target="_blank" rel="noreferrer">View Wikipedia source ↗</a><button className="primary wide" onClick={()=>startRound(false)}>Next player</button><button className="ghost wide" onClick={()=>setRound(null)}>Back to modes</button></div>}
        <div className="source-status">{round.live?'● Live career loaded from Wikipedia':'● Curated fallback career'}</div>
      </section>
      {message&&<div className="toast" role="status">{message}</div>}
    </main>;
  }

  const progress=tier.next?Math.min(100,((profile.xp-tier.current[1])/(tier.next[1]-tier.current[1]))*100):100;
  return <main className="shell">
    <header className="topbar"><div className="brand">WIKIBALL ⚽️</div><div className="wallet"><span>🔥 {profile.streak}</span><span>🪙 {profile.coins}</span></div></header>
    <section className="hero"><div className="hero-copy"><span className="kicker">THE FOOTBALL CAREER GUESSING GAME</span><h1>Know the journey.<br/><em>Name the player.</em></h1><p>Follow the clubs. Read the eras. Guess the footballer. Earn XP, build streaks and climb from Rookie to Legend.</p></div><div className="tier-card"><div className="tier-top"><span className="tier-icon">{tier.current[2]}</span><div><small>CURRENT TIER</small><strong>{tier.current[0]}</strong></div><b>{profile.xp} XP</b></div><div className="xp-track"><i style={{width:`${progress}%`}}/></div><div className="tier-bottom"><span>{tier.current[1]} XP</span><span>{tier.next?`${tier.next[0]} · ${tier.next[1]} XP`:'Maximum tier'}</span></div></div></section>

    <section className="mode-grid"><button className="mode daily-mode" onClick={()=>startRound(true)} disabled={loading}><span>📅</span><div><b>Daily Challenge</b><small>One shared player every day · bonus XP</small></div><i>Play →</i></button><button className="mode quick-mode" onClick={()=>startRound(false)} disabled={loading||!pool.length}><span>⚡</span><div><b>Quick Play</b><small>{pool.length} players match your filters</small></div><i>{loading?'Loading…':'Play →'}</i></button></section>

    <section className="filters-card"><div className="section-title"><div><span className="kicker">BUILD YOUR ROUND</span><h2>Play your football era</h2></div><button className="ghost" onClick={resetFilters}>Reset</button></div>
      <div className="filter-grid">
        <label><span>🎯 Difficulty</span><select value={filters.difficulty} onChange={e=>setFilters({...filters,difficulty:e.target.value as Filters['difficulty']})}><option value="all">Any difficulty</option><option value="easy">Easy · Icons</option><option value="medium">Medium · Fans</option><option value="hard">Hard · Sickos 😈</option></select></label>
        <label><span>🗓️ Decade</span><select value={filters.decade} onChange={e=>setFilters({...filters,decade:e.target.value})}><option value="all">Any decade</option>{decades.map(d=><option key={d}>{d}</option>)}</select></label>
        <label><span>🛡️ Team / club</span><select value={filters.team} onChange={e=>setFilters({...filters,team:e.target.value})}><option value="all">Any club</option>{teams.map(t=><option key={t}>{t}</option>)}</select></label>
        <label><span>🌍 Region</span><select value={filters.region} onChange={e=>setFilters({...filters,region:e.target.value})}><option value="all">Any region</option>{regions.map(r=><option key={r}>{r}</option>)}</select></label>
      </div>
      <div className={`match-count ${pool.length?'':'empty'}`}>{pool.length?<>✨ <b>{pool.length}</b> possible players with this combination</>:<>⚠️ No players match yet. Try resetting a filter.</>}</div>
    </section>

    <section className="stats"><div><span>✅</span><b>{profile.correct}</b><small>Correct</small></div><div><span>🎮</span><b>{profile.played}</b><small>Played</small></div><div><span>🔥</span><b>{profile.bestStreak}</b><small>Best streak</small></div><div><span>🏆</span><b>{profile.played?Math.round(profile.correct/profile.played*100):0}%</b><small>Accuracy</small></div></section>
    {message&&<div className="toast" role="status">{message}</div>}
    <footer>Career data fetched from Wikipedia when available · Wikiball v0.1</footer>
  </main>;
}
