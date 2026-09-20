"""Scan Swift string literals, including nested interpolation expressions."""
import re,json
han=re.compile(r'[\u3400-\u9fff]')
# Swift string scanner: nested interpolation expressions can contain their own strings.
def parse(s,start):
 i=start+1;parts=[];expressions=[];piece=''
 while i<len(s):
  if s[i]=='"':
   parts.append(piece);return i+1,parts,expressions
  if s[i:i+2]=='\\(':
   parts.append(piece);piece='';j=i+2;begin=j;depth=1
   while depth:
    if s[j]=='"':j,_,_=parse(s,j);continue
    if s[j]=='(':depth+=1
    if s[j]==')':depth-=1
    j+=1
   expressions.append((begin,j-1));i=j;continue
  if s[i]=='\\':piece+=s[i:i+2];i+=2
  else:piece+=s[i];i+=1
 raise ValueError(s[start:start+80])
def strings(s):
 i=0
 while i<len(s):
  if s[i:i+2]=='//':
   e=s.find('\n',i);i=len(s) if e<0 else e;continue
  if s[i:i+2]=='/*':i=s.index('*/',i)+2;continue
  if s[i]=='"':
   end,parts,expr=parse(s,i);yield i,end,parts,expr;i=end
  else:i+=1


def extract(s):
 for a,b,parts,expressions in strings(s):
  if s[:a].rstrip().endswith('L10n.text('):
   template=''.join(part+('{'+str(i)+'}' if i<len(expressions) else '') for i,part in enumerate(parts))
   yield json.loads('"'+template+'"')
  for c,d in expressions:yield from extract(s[c:d])
