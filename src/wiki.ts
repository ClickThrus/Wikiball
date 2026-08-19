import type { CareerStop } from './data';

function unwrapTemplates(value:string){
  let out=value;
  for(let i=0;i<4;i++){
    out=out.replace(/\{\{(?:nowrap|small|nobr)\|([^{}]*)\}\}/gi,'$1');
  }
  return out;
}

function cleanWiki(value:string){
  return unwrapTemplates(value)
    .replace(/<ref[^>]*>[\s\S]*?<\/ref>/gi,'')
    .replace(/<ref[^/>]*\/>/gi,'')
    .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g,'$2')
    .replace(/\[\[([^\]]+)\]\]/g,'$1')
    .replace(/\{\{flagicon\|[^}]+\}\}/gi,'')
    .replace(/\{\{[^{}]*\}\}/g,'')
    .replace(/<[^>]+>/g,'')
    .replace(/''+/g,'')
    .replace(/&nbsp;/g,' ')
    .replace(/\s+/g,' ')
    .trim();
}

export function parseCareer(wikitext:string):CareerStop[]{
  const years=new Map<number,string>();
  const clubs=new Map<number,string>();
  for(const line of wikitext.split('\n')){
    const y=line.match(/^\s*\|\s*years(\d+)\s*=\s*(.+?)\s*$/i);
    if(y) years.set(Number(y[1]),cleanWiki(y[2]));
    const c=line.match(/^\s*\|\s*clubs(\d+)\s*=\s*(.+?)\s*$/i);
    if(c) clubs.set(Number(c[1]),cleanWiki(c[2]));
  }
  return Array.from(clubs.keys()).sort((a,b)=>a-b).flatMap(i=>{
    const club=clubs.get(i)?.replace(/^→\s*/,'').trim();
    const yr=years.get(i)?.trim();
    return club&&yr ? [{years:yr,club}] : [];
  });
}

export async function fetchCareer(title:string):Promise<CareerStop[]>{
  const params=new URLSearchParams({action:'parse',page:title,prop:'wikitext',format:'json',origin:'*'});
  const response=await fetch(`https://en.wikipedia.org/w/api.php?${params.toString()}`);
  if(!response.ok) throw new Error('Wikipedia request failed');
  const json=await response.json() as {parse?:{wikitext?:{'*'?:string}}};
  const text=json.parse?.wikitext?.['*'];
  if(!text) throw new Error('No Wikipedia wikitext');
  const career=parseCareer(text);
  if(career.length<2) throw new Error('Career parser returned too little data');
  return career;
}
