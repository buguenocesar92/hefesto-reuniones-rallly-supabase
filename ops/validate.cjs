const fs=require('node:fs');const e=process.env;
const fail=m=>{console.error(m);process.exit(1)};
const local=e.BOOTSTRAP_MODE==='true';let u,db,direct;
try{u=new URL(e.NEXT_PUBLIC_BASE_URL);db=new URL(e.DATABASE_URL);direct=new URL(e.DIRECT_DATABASE_URL)}catch{fail('URL invalida')}
if(u.username||u.password||u.search||u.hash||u.pathname!=='/')fail('Dominio raiz requerido');
const dbname=e.DB_NAME||'postgres';
const sslmode=e.DB_SSLMODE||'verify-full';
if(local){if(e.NEXT_PUBLIC_BASE_URL!=='http://localhost:8115')fail('Bootstrap solo localhost8115')}
else{if(u.protocol!=='https:')fail('HTTPS requerido');
 if(e.SMTP_READY==='true'){
   for(const k of ['SMTP_HOST','SMTP_USER','SMTP_PWD'])if(!e[k]||e[k]==='REEMPLAZAR')fail('Completar SMTP');
   if(e.SMTP_PORT!=='465'||e.SMTP_SECURE!=='true'||e.SMTP_REJECT_UNAUTHORIZED!=='true')fail('SMTP465 con TLS verificado requerido');
 }
 if(e.REGISTRATION_ENABLED!=='false')fail('Cerrar registro publico despues del setup');}
if(!/^[a-f0-9]{64}$/.test(e.SECRET_PASSWORD||''))fail('Configurar secreto64hex');
const caPath=e.DB_SSLROOTCERT||'/certs/ca.crt';
const certPath=e.DB_SSLCERT||'/certs/ca.crt';
if(sslmode==='verify-full'&&!fs.existsSync(caPath))fail('Falta CA DB');
for(const x of [db,direct])if(x.protocol!=='postgresql:'||x.port!=='5432'||x.pathname!==`/${dbname}`)fail('DB PostgreSQL5432 requerida');
if(db.host!==direct.host||db.username!==direct.username||db.password!==direct.password)fail('Usar el mismo destino y rol en ambas conexiones');
if(!/^[a-f0-9]{64}$/.test(db.password))fail('Clave DB64hex requerida');
if(sslmode==='verify-full'){
  if(db.searchParams.get('sslmode')!=='verify-full'||db.searchParams.get('sslrootcert')!==caPath)fail('TLS runtime verificado requerido');
  if(direct.searchParams.get('sslmode')!=='require'||direct.searchParams.get('sslaccept')!=='strict'||direct.searchParams.get('sslcert')!==certPath)fail('TLS Prisma estricto requerido');
}
if(!e.INITIAL_ADMIN_EMAIL?.includes('@')||e.INITIAL_ADMIN_EMAIL.includes('REEMPLAZAR')||e.INITIAL_ADMIN_EMAIL.endsWith('.invalid'))fail('Configurar correo administrador real');
if(!e.ALLOWED_EMAILS?.trim())fail('No dejar allowlist vacia');
console.log('Configuracion previa comprobada; no se ha probado TLS, SMTP ni la cuenta desde este guard.');