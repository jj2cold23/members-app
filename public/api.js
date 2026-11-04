export class CommunityAPI {
  constructor(config, storage=globalThis.sessionStorage){this.url=(config.supabaseUrl||'').replace(/\/$/,'');this.key=config.supabaseKey;this.storage=storage;try{this.session=JSON.parse(storage.getItem('cg-session')||'null');}catch{this.session=null;storage.removeItem('cg-session');}}
  get configured(){return /^https:\/\//.test(this.url)&&Boolean(this.key);}
  save(session){this.session=session;if(session)this.storage.setItem('cg-session',JSON.stringify(session));else this.storage.removeItem('cg-session');}
  async request(path,{method='GET',body,auth=true}={}){
    if(!this.configured)throw Error('Backend setup is required. See README.md.');
    if(auth&&this.session?.expires_at*1000<Date.now()+60000)await this.refresh();
    const response=await fetch(this.url+path,{method,headers:{apikey:this.key,...(auth&&this.session?{Authorization:`Bearer ${this.session.access_token}`} : {}),'Content-Type':'application/json',Prefer:'return=representation'},...(body!==undefined?{body:JSON.stringify(body)}:{})});
    const text=await response.text();let result;try{result=text?JSON.parse(text):null;}catch{throw Error('The server returned an unexpected response.');}
    if(!response.ok)throw Error(result?.msg||result?.message||result?.error_description||result?.error||`Request failed (${response.status})`);
    return result;
  }
  async refresh(){try{const s=await this.request('/auth/v1/token?grant_type=refresh_token',{method:'POST',auth:false,body:{refresh_token:this.session.refresh_token}});this.save({...s,expires_at:Math.floor(Date.now()/1000)+s.expires_in});}catch(e){this.save(null);throw Error('Your session expired. Please sign in again.');}}
  async login(email,password){const s=await this.request('/auth/v1/token?grant_type=password',{method:'POST',auth:false,body:{email,password}});this.save({...s,expires_at:Math.floor(Date.now()/1000)+s.expires_in});return s;}
  async signup(email,password,name){const s=await this.request('/auth/v1/signup',{method:'POST',auth:false,body:{email,password,data:{name}}});if(s.access_token)this.save({...s,expires_at:Math.floor(Date.now()/1000)+s.expires_in});return s;}
  async logout(){try{if(this.session)await this.request('/auth/v1/logout',{method:'POST'});}finally{this.save(null);}}
  async user(){return this.request('/auth/v1/user');}
  list(table){return this.request(`/rest/v1/${table}?select=*&order=created_at.desc`);}
  async write(table,data,id){const result=await this.request(`/rest/v1/${table}${id?'?id=eq.'+encodeURIComponent(id):''}`,{method:id?'PATCH':'POST',body:data});if(!result?.length)throw Error('Nothing was saved. You may not own this record.');return result[0];}
  async remove(table,id){const result=await this.request(`/rest/v1/${table}?id=eq.${encodeURIComponent(id)}`,{method:'DELETE'});if(!result?.length)throw Error('Nothing was deleted. You may not own this record.');}
}
