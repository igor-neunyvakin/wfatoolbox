function cell2csv(filename,cellArray,delimiter,float_format,int_format,string_format)
% CELL2CSV(filename,cellArray,delimiter,float_format,int_format,string_format)
% Writes cell array content into a *.csv file.
% Accepts cell arrays containing strings, numeric, empty or logicals. 
% Output of logicals is 0 / 1. Length of numeric and logicals must be 1.
%
%
% Parameters:
% name    size type       = description
%
% required parameter:
% filename [?](char)      = Name of the file to save including file extension. Full or relativ path.
% cellarray [? X ?](cell) = Cell Array where the data is in.
%
% optional parameters:
% delimiter [1](char)     = seperating sign, default: ','
% float_format [?](char)  = formatSpec for floating-point numbers, default: '%f'
% int_format [?](char)    = formatSpec for integers, default: '%i'
% string_format [?](char) = formatSpec for strings, default: '%s'
%
% If using an optional parameter all previous parameters must be set
% whole-number double or single are treated as integers
% formatSpec needs to be accepted by sprintf: <a href="matlab: web('http://de.mathworks.com/help/matlab/ref/sprintf.html#inputarg_formatSpec')">formatSpec</a>.
% See also SPRINTF
%
% by Nicolas Nau , 2016


if nargin<6 %Definiere optionale Parameter wenn nicht übergeben
    string_format='%s';
end
if nargin<5
    int_format='%i';
end
if nargin<4
    float_format='%f';
end
if nargin<3
    delimiter = ',';
end


string_s=double([string_format,delimiter]); %Erweitere formatSpec um den delimiter und konvertiere zu double
float_s=double([float_format,delimiter]);
int_s=double([int_format,delimiter]);
sl=length(string_s); %Bestimme die Länge des formatSpecs
fl=length(float_s);
il=length(int_s);
ll=max([sl,fl,il]); %Bestimme die Länge des größsten formatSpec


string=cellfun(@ischar,cellArray) | cellfun(@isempty,cellArray); %Logische Matrix für string_format
float=~string; % alle nicht Strings sind Zahlen
int=float;     % nur Werte in float können ganzzahlig sein
int(float)=cell2mat(cellfun(@(x)round(double(x))==x,cellArray(float),'UniformOutput',false)); %Prüfe alle float-Werte ob ganzzahlig, double() um error in Matlabversionen kleiner 2015a zu vermeiden wenn logicals übergeben werden (kann ggf. entfernt werden)
float=xor(float,int); % ganzzahlige Zahlen aus float-Logik löschen


char_p=NaN(size(cellArray,2)*ll,size(cellArray,1));% Preallocation, transponiert wegen eindimensionalem Zugriff Z.64, Dimension 2 um ll gestreckt damit die maximal Anzahl an Zeichen aus den formatSpecs eingetragen werden können, NaN als nicht belegter Platzhalter

index=find(float')'; %finde Indizes der Zellen, Logik transponiert um char_p zu entsprechen, find Output transporniert damit dimensionen in Z.63 passen
if ~isempty(index) %if fängt den Fall ab dass keine Zellen des Typs vorhanden sind
    index=index*ll-(ll-1); %Strecke die Indexwerte auf die Indizes des ersten Zeichens der formatSpec in char_p
    access=repmat(index,1,fl)+reshape(ones(length(index),fl)*diag(0:fl-1),1,[]); %Eindimensionaler Zugriffsvektor für char_p, jeweils der gestreckte Indexwert und von der Länge des formatSpecs abhängigen nachfolgenden Werte 
    char_p(sort(access))=repmat(float_s,1,length(index)); % Vervielfältige formatSpec und schreibe es in char_p, acces muss sortiert werden damit es der Reihenfolge des repmat Outputs entspricht.
end

index=find(int')';
if ~isempty(index)
    index=index*ll-(ll-1);
    access=repmat(index,1,il)+reshape(ones(length(index),il)*diag(0:il-1),1,[]);
    char_p(sort(access))=repmat(int_s,1,length(index));
end

index=find(string')';
if ~isempty(index)
    index=index*ll-(ll-1);
    access=repmat(index,1,sl)+reshape(ones(length(index),sl)*diag(0:sl-1),1,[]);
    char_p(sort(access))=repmat(string_s,1,length(index));
end

char_p=char_p'; %Transponieren damit Matrix wieder in ihrer ursprünglichen Form

text=cell(size(char_p,1),1); %Preallocation für text
for i=1:size(char_p,1)
    text{i}=sprintf([char(char_p(i,~isnan(char_p(i,:)))),'\n'],cellArray{i,:}); %Schreibe cellArray zeilenweise in text, ~isnan eleminiert NaN-Werte die auftreten wenn die formatSpecs nicht alle gleich Lang sind, char() konvertiert die double Werte zurück in strings.
    text{i}(end-1)=[]; %Eleminiert den letzen delimiter, da zwischen dem letzen Wert einer Zeile und dem "newLine" zeichen kein delimiter sein soll.
end
fileID = fopen(filename,'w'); %Öffne Datei
fprintf(fileID,[text{:}]); %Schreibe text in Datei
fclose(fileID); %Schließe Datei


