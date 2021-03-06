unit uAtualizar;


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, IdHTTP,
  StdCtrls, IdComponent, Grids, strUtils, ExtCtrls;

type

  { TfrmAtualizar }

  TfrmAtualizar = class(TForm)
    Button1: TButton;
    IdHTTP1: TIdHTTP;
    Memo1: TMemo;
    sgrJogos: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure IdHTTP1Redirect(Sender: TObject; var dest: string;
      var NumRedirect: Integer; var Handled: boolean; var VMethod: TIdHTTPMethod
      );
    procedure IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAtualizar: TfrmAtualizar;

implementation
uses  uHtml_Analisador, zipper, uIntralot;

{$R *.lfm}

{ TfrmAtualizar }

procedure TfrmAtualizar.Button1Click(Sender: TObject);
var
  jogo_zip: TMemoryStream;
  strHtml_Conteudo: TStringStream;
  strArquivo_Html: TFileStream;

  strHtml: AnsiString;
  //myHtml: TIntralot_Html;
  strBuffer: array[0..1024] of char;
  iSize: Int64;
  iBytes_Lidos: LongInt;


  myHtml_Analise: Tfb_Tokenizador_Html;
  meus_tokens : TStrings;

  arquivo_zip : TUnZipper;
  arquivo_zip_entradas :TFullZipFileEntries;
  arquivo_zip_entrada : TFullZipFileEntry;


  //arquivo_zip_entradas: TZipFileEntries;
  entrada_zip : TZipFileEntry;
  iEntradas: integer;
  bArquivo_Encontrado: Boolean;
  iA: Integer;
  strArquivo: AnsiString;
  zip_todos_arquivos: TStrings;
  teste_intralot: TIntralot;
  strErro: String;
  meus_jogos: TStrings;
  iByte: Byte;

begin




  //idHttp1 := TIdHttp.Create(nil);
  try
    jogo_zip := TMemoryStream.Create;
    strHtml_Conteudo := TStringStream.Create('');
    try
      idHttp1.AllowCookies:= true;
      {
       idHttp1.Get('http://www.intralot.com.br/newsite/minas5/resultado/?sorteio=716&data=Data+do+sorteio', jogo_zip);
       jogo_zip.SaveToFile('./minas5_sorteio_716.html');
       jogo_zip.Clear;
       jogo_zip.FreeInstance;
      }

      try
         //idHttp1.Get('http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_lotfac.zip', jogo_Zip);
         idHttp1.Get('http://www.intralot.com.br/newsite/resultados/?jogo=todos&busca=numero&range=402867-402868', jogo_zip);
      except
            if (idHttp1.ResponseCode >= 300) and (idHttp1.ResponseCode <= 399) then begin
              // Indica redirecionamento, devemos fazer um get novamente.
              try
                 //idHttp1.Get('http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_lotfac.zip', jogo_Zip);

                idHttp1.Get('http://www.intralot.com.br/newsite/resultados/?jogo=todos&busca=numero&range=402867-402868', jogo_zip);
              except
                    On exc: Exception do begin
		                      if idHttp1.ResponseCode <> 200 then begin
		                        // Um erro ocorreu, devemos sair e avisar o usuário.
		                        MessageDlg(exc.Message, tMsgDlgType.mtInformation, [mbOk], 0);
				      end;
		    end;
	      end;
	    end;
      end;

      // Vamos criar diretório de não existe
      if DirectoryExists('./loteria/') = false then begin
         MkDir('./loteria/');
      end;

      //jogo_zip.SaveToFile('./loteria/intralot_minas_5_sorteio_recente.htm');


      jogo_zip.SaveToFile('./loteria/intralot_jogos.htm');
      jogo_zip.Clear;
      FreeAndNil(jogo_zip);

      // Vamos verificar se existe
      //strArquivo := './loteria/intralot_minas_5_sorteio_recente.htm';

      strArquivo := './loteria/intralot_jogos.htm';
      if FileExists(strArquivo) = false then
      begin
        MessageDlg('Arquivo não existe.', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;

      // Vamos abrir o arquivo

      try
         strArquivo_Html := TFileStream.Create(strArquivo, fmOpenRead);
      except
            On exc: Exception do begin
               MessageDlg(exc.Message, TMsgDlgType.mtError, [mbOk], 0);
	    end;
      end;
      iSize := strArquivo_Html.Size;

      if iSize = 0 then begin
        MessageDlg('Arquivo está vazio.', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;





      {


      jogo_zip.SaveToFile('./loteria/d_lotfac.zip');
      jogo_zip.Clear;
      FreeAndNil(jogo_zip);

      if FileExists('./loteria/d_lotfac.zip') = false then begin
        MessageDlg('Arquivo não existe: ./loteria/d_lotfac.zip', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;

      // Vamos descompactar o arquivo zip
      arquivo_zip := TUnZipper.Create;
      arquivo_zip.FileName:= './loteria/d_lotfac.zip';
      arquivo_zip.Examine;

      arquivo_zip_entradas := arquivo_zip.Entries;
      arquivo_zip_entrada := arquivo_zip_entradas.FullEntries[0];
      strArquivo := arquivo_zip_entrada.ArchiveFileName;

      // Nas loterias da caixa, todos os resultados ficam em um único arquivo zip.
      // Este arquivo zip, tem 2 arquivos, um de extensão .gif e outro de extensão
      // html.
      // Então, devemos verificar se a quantidade de entradas é igual a 2, senão
      // indicaremos um erro.
      if arquivo_zip_entradas.Count <> 2 then begin
        MessageDlg('Nos jogos da caixa, deve haver 2 arquivos dentro de um arquivo zip',
        tMsgDlgType.mtConfirmation, [mbOk], 0);
        Exit;
      end;

      // Se chegamos até aqui, quer dizer, que a quantidade é igual a 2.
      bArquivo_Encontrado := false;

      for iA := 0 to arquivo_Zip_Entradas.Count do begin
        arquivo_zip_entrada := arquivo_zip_entradas.FullEntries[iA];
        if AnsiEndsStr('.HTM', UpperCase(arquivo_zip_entrada.ArchiveFileName)) = true then begin
           bArquivo_Encontrado := true;
           break;
        end;
      end;


      if bArquivo_Encontrado = false then begin
        MessageDlg('Arquivo extensão ''htm'' não localizado!!!', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;

      // Vamos extrair o arquivo encontrado.
      arquivo_zip.OutputPath:= './loteria/extraido/';
      arquivo_zip.UnZipAllFiles;


      strArquivo := './loteria/extraido/' + arquivo_zip_entrada.ArchiveFileName;
      if FileExists(strARquivo) = false then begin
        MessageDlg('Arquivo não existe.', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;

      strArquivo_Html := TFileStream.Create(strArquivo, fmOpenRead);
      iSize := strArquivo_Html.Size;

      if iSize = 0 then begin
        MessageDlg('Arquivo está vazio.', TMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;
      }



      {
       FillChar(strBuffer, 1024, #0);
       iBytes_Lidos := strArquivo_Html.Read(strBuffer, 1024);
       strHtml := '';
       while iBytes_Lidos <> 0 do begin
         strHtml := strHtml + strBuffer;
         // Limpar o 'strBuffer' não pode ficar lixo.
         FillChar(strBuffer, 1024, #0);
         iBytes_Lidos := strArquivo_Html.Read(strBuffer, 1024);
       end;
      }

      strArquivo_Html.Seek(0, TSeekOrigin.soBeginning);
      if strArquivo_Html.Size = 0 then begin
        MessageDlg('Arquivo está vazio.', tMsgDlgType.mtError, [mbOk], 0);
        Exit;
      end;

      strHtml := '';
      while strArquivo_Html.Position < strArquivo_Html.Size do begin
                 iByte := strArquivo_Html.ReadByte;
                 strHtml := strHtml + chr(iByte);

      end;


      // Fechar fluxo
      strArquivo_Html.Free;

      //myHtml.html_Conteudo:= strHtml;

      myHtml_Analise := Tfb_Tokenizador_Html.Create;
      myHtml_Analise.html_Conteudo:= strHtml;
      meus_tokens := TStringList.Create;
      myHtml_Analise.html_Conteudo:= Utf8toAnsi(strHtml);


      if myHtml_Analise.Analisar_Html = true then begin
        MessageDlg('Analisado com sucesso!!!', TMsgDlgType.mtConfirmation,
        [mbOk], 0);

        // Vamos preencher 1 a 1:

        memo1.Clear;
        for iA := 0 to myHtml_Analise.html_Tokens.Count - 1 do begin
          memo1.Lines.Add(IntToStr(iA) + '     ' + myHtml_Analise.html_Tokens.Strings[iA]);
          ;
        end;
      end;

      memo1.Refresh;

      meus_tokens.Free;

      memo1.Lines.SaveToFile('./loteria/do_memo1.htm');

      //Exit;

      teste_intralot:=TIntralot.Create;
      strErro := '';

      meus_jogos := TStringList.Create;
      meus_jogos.Clear;

      if teste_intralot.Analisar('MINAS5', myHtml_Analise.html_Tokens, meus_jogos, strErro) = false then begin
         MessageDlg('Erro: ' + strErro, TMsgDlgType.mtError, [mbOk], 0);
         Exit;
      end;

      // Vamos salvar dos jogos, por enquanto.
      if meus_jogos.Count <> 0 then begin
         meus_jogos.SaveToFile('./loteria/intralot_minas5_resultado_5_nov_2015.csv');
         meus_jogos.Clear;
      end;


      myHtml_Analise.Free;
      teste_intralot.Free;
      //meus_jogos.Free;
      meus_tokens.Free;
      strHtml_Conteudo.Free;








    except
      On exc:Exception do begin
        MessageDlg('Erro: ' + exc.Message, TMsgDlgType.mtInformation, [mbOk], 0);
      end;


    end;
  finally

  end;
end;

procedure TfrmAtualizar.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  //self.Memo1.Lines.Clear;
  //CloseAction := TCloseAction.caFree;
end;

procedure TfrmAtualizar.IdHTTP1Redirect(Sender: TObject; var dest: string;
  var NumRedirect: Integer; var Handled: boolean; var VMethod: TIdHTTPMethod);
begin
  //memo1.Lines.Add('dest: ' + dest);

end;

procedure TfrmAtualizar.IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
var
  Http: TIdHTTP;
  ContentLength: Int64;
  Percent: Integer;
begin
{
 Http := TIdHTTP(ASender);
 ContentLength := Http.Response.ContentLength;

 //Percent := 100*AWorkCount div ContentLength;

 //Memo1.Lines.Add(IntToStr(Percent));

 if (Pos('chunked', LowerCase(Http.Response.ResponseText)) = 0) and
    (ContentLength > 0) then
 begin
   Percent := 100*AWorkCount div ContentLength;

   Memo1.Lines.Add(IntToStr(Percent));
 end;
}

end;

end.

