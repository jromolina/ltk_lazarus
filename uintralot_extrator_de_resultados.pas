unit uIntralot_extrator_de_resultados;

{
     Autor : Fábio Moura de Oliveira
     Data  : 06/12/2015.

     Esta unit, extrai os resultados do site da intralot, que ficam na url abaixo:

                                      www.intralot/newsite/resultados

     Há dois tipos de consulta, por data de jogo e por número do jogo, como funciona:

     O jogador escolhe o jogo, as opções são:
     * Todos os jogos;
     * Keno Minas
     * Minas 5
     * Multiplix
     * LotoMinas
     * Totolot.

     Após escolher o jogo o usuário seleciona se quer por data do jogo ou se por número do jogo.
     Após isto, clica no botão 'BUSCAR'.

     Quando o usuário clica no botão é gerado uma solicitação GET, como é sabido, solicitações
     GET, o conteúdo do formulário é enviado na url, no formato propriedade=valor.

     Haverá na url duas formas de enviar a consulta, para a consulta por data de jogo e
     por número de jogo.

     Por data de jogo, segue-se nomenclatura.

     www.intralot.com.br/newsite/resultados/?

     Após a url acima, haverá os parâmetros abaixo:
     'jogo=',  após o símbolo haverá o nome do jogo, cada jogo há um nome diferente
               do que está na caixa de combinação, segue-se, para o jogo:
               'Todos os jogos', será              'todos';
               'Minas 5', será                     'minas-5';
               'Keno Minas', será                  'keno-minas';
               'Multiplix', será                   'multplix';
               'Loto Minas', será                  'loto-minas';
               'Totolot', será                     'totolot'.

               Os valores 'todos', 'minas-5', 'keno-minas', 'multplix', 'lotominas' e
               'totolot', são todos valores do campo 'value' do tag 'select'.


     Em seguida, o tipo da busca, se for por data, o string de consulta será:

     &busca=data

     Entretanto, se for por concurso, será:

     &busca=numero

     Em seguida, haverá a string de consulta:

     &range=

     Em seguida, vem o intervalo que escolhermos, se a busca foi por data,
     por exemplo, se o usuário selecionou o intervalo: 01/12/2015 a 06/12/2015,
     ficará assim:

     01122015-06122015,

     observe que, se o dia ou mês for menor que 10, devemos acrescentar sempre um
     zero a esquerda, ou seja, dia e mês, sempre tem que haver dois algarismos.

     Entretanto, se a busca foi por número do jogo, então, por exemplo,
     se o usuário selecionou o jogo número 1 (um) a 1000, então deve-se colocado
     a informação na url desta forma:

     1-1000

     Em seguida, ao enviarmos a url codificada novamente para o servidor, estaremos
     simulando uma consulta.
     Se esta consulta, retorna mais de uma página, conseguiremos detectar isto
     dentro do conteúdo html, pois há um tag denominado: '<div class="pagination"
     que guarda algumas páginas, as 8 primeiras e em seguida, a última das páginas.

     Na url, cada página é identificada pelo string: &page=xxx, onde xxx, indica o número
     da página, a url que enviamos será a página 1, ela não terá o string: '&page=1',
     entretanto, as demais páginas terão.

     Pode-se observar, no conteúdo html, que o link para a próxima página
     está localizado dentro do tag: '<div class="pagination".
     Dentro do tag, terá até 8 páginas seguintes, e terá um link para a última página.

     Então, o que nosso extrator de resultados, fará na tag '<div class="pagination":
     Percorrerá todos os links que está somente na primeira página, e como na primeira
     página é identificada a última página, não precisaremos nas próximas páginas
     analisar o que está entre '<div class="pagination".
}



{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uHtml_Analisador, strUtils;

type

  { Tfb_Intralot_Resultados }

  Tfb_Intralot_Resultados = class
    lista_de_resultados: TStrings;

    // Indica se cabeçalho já foi inserido.
    cabecalho_existe : boolean;

    strErro: string;

    function extrair_por_numero_do_jogo(strJogo: string;
      iJogo_Inicial: integer; iJogo_Final: integer): boolean;

    function extrair_por_data_do_jogo(strJogo: string; iData_Inicial: string;
      iData_Final: string): boolean;

  public
    function extrair(var resultado_dos_jogos: TSTrings; tokens_html: TStrings
					): boolean;
    property ultimo_erro: string read strErro;

  private
		function Gravar_Cabecalho(strJogo: string): boolean;
		function intervalo_valido_das_bolas(jogo_tipo: string; bola_numero: integer
					): boolean;
		function jogo_valido(var strJogo: string): boolean;
		function Tag_Abre_e_Fecha(tokens_html: TStrings; strIdentificador_Tag: string;
					uIndice_Inicio: integer; uIndice_Fim: integer; out uIndice_Tag: integer
			): boolean;
		function Validar_Data_Hora(strData_Hora: string; var strData: string;
					var strHora: string): boolean;
		function Validar_Hora(strData_Hora: string): boolean;
    function Validar_Jogo(strJogo: string): boolean;
  end;

implementation

{ Tfb_Intralot_Resultados }

// Esta função valida se o jogo está correto.
function Tfb_Intralot_Resultados.Validar_Jogo(strJogo: string): boolean;
begin
  strJogo := LowerCase(strJogo);

  case strJogo of
    'todos':
      Result := True;
    'keno-minas':
      Result := True;
    'minas-5':
      Result := True;
    'multplix':
      Result := True;
    'loto-minas':
      Result := True;
    'totolot':
      Result := True;
    else
      Result := False;
  end;

end;

{
 A função abaixo
 }

function Tfb_Intralot_Resultados.extrair_por_numero_do_jogo(strJogo: string;
  iJogo_Inicial: integer; iJogo_Final: integer): boolean;
var
  strUrl_do_Jogo: string;
begin
  if not Validar_Jogo(strJogo) then
  begin
    strErro := 'Jogo inválido.';
    Exit(False);
  end;

  // Vamos criar a url do jogo:
  strUrl_do_Jogo := 'http://www.intralot.com.br/newsite/resultados?';
  strUrl_do_Jogo := strUrl_do_Jogo + Format(
    'jogo=%s&busca=numero&range=%d-%d', [strJogo, iJogo_Inicial, iJogo_Final]);

end;

function Tfb_Intralot_Resultados.extrair_por_data_do_jogo(strJogo: string;
  iData_Inicial: string; iData_Final: string): boolean;
begin

end;

{
    Esta função grava o cabeçalho, que vai na primeira linha do arquivo:
    Este programa grava o resultado dos arquivos em formato csv.
    Na primeira linha, o nome dos cabeçalhos são separados por ';', pois é um formato csv.
    JOGO_TIPO:         O nome do jogo.
    CONCURSO:          O número do concurso.
    DATA SORTEIO:      A data do sorteio.
    BOLA1:             A primeira bola sorteada do jogo.
}

function Tfb_Intralot_Resultados.Gravar_Cabecalho(strJogo: string): boolean;
var
			strCabecalho: String;
			iA: Integer;
begin
  strCabecalho := 'JOGO_TIPO;CONCURSO;DATA SORTEIO';
  case UpperCase(strJogo) of
    'INTRALOT_MINAS_5':     for iA := 1 to 5 do strCabecalho := strCabecalho + format(';BOLA%d', [iA]);
    'INTRALOT_LOTO_MINAS':  for iA := 1 to 6 do strCabecalho := strCabecalho + format(';BOLA%d', [iA]);
    'INTRALOT_KENO_MINAS':  for iA := 1 to 20 do strCabecalho := strCabecalho + format(';BOLA%d', [iA]);
    'INTRALOT_MULTIPLIX' :
    begin
         strErro := 'Jogo ainda não implementado.';
         Exit(False);
		end;
    'INTRALOT_TOTOLOT':
    begin
      strErro := 'Jogo INTRALOT_TOTOLOT não será implementado, pois os números não são ' +
                 ' escolhidos pelo usuário e sim pelo sistema.';
      Exit(False);
		end;
    else begin
      strErro := 'Jogo ' + strJogo + ' inexistente.';
      Exit(False);
		end;
	end;

  lista_de_resultados.Add(strCabecalho);
end;

// O método 'extrair' é a função núcleo do extrator de resultados, é onde os tags
// html são analisados sintaticamente e se válidos o resultado de um ou mais jogos
// são retornados.
// Os tokens já foram separados, aqui, simplesmente, os tokens são validados
// sintaticamente conforme descrito no site da intralot.
function Tfb_Intralot_Resultados.extrair(var resultado_dos_jogos: TSTrings;tokens_html: TStrings): boolean;
var
			uTotal_de_Tokens: Integer;
			uIndice: Integer;
			uTag_Div_Fechamento_Indice: Integer;
			jogo_resultado: TStrings;
			strJogo: String;
			tag_fim_result_item: integer;
			concurso_data_hora: String;
			iEspaco_Posicao: SizeInt;
			numero_do_concurso: String;
			tag_fim_class_bolas: Integer;
			uBola_Numero: Integer;
			strData_Hora: String;
			strData: string;
			strHora: string;
			pedra_preciosa_simbolo: String;
			strTexto_Resultado: String;
			iA: Integer;
begin
  uTotal_de_Tokens := tokens_html.Count - 1;

  // O jogo sempre fica entre o tag <div class="resultados"     </div>
  // Então, devemos localizar onde está este token.
  jogo_resultado := TStrings(TStringList.Create);

  if Assigned(lista_de_resultados) then begin
    FreeAndNil(lista_de_resultados);
	end;

  lista_de_Resultados := TStrings(TStringList.Create);
  if not Assigned(lista_de_resultados) then
  begin
    strErro := 'Não foi possível criar lista de resultados.';
    Exit(False);
  end;

  cabecalho_existe := false;

  // Vamos localizar o primeiro token que começa com '<div'
  uIndice := tokens_html.IndexOf('<div');


  // O loop abaixo tem a finalidade de localizar dentro do conteúdo html
  // a palavra formada pelos tokens html: <div class = "resultados >"
  // Estes tokens indica o início do resultados dos jogos da site da intralot.
  while uIndice <= uTotal_de_Tokens do
  begin
    // Se os próximos quatros campos é igual a '<div', 'class', '=' e '"resultados"',
    // encontramos o início.
    if (tokens_html.Strings[uIndice + 0] = '<div') and
      (tokens_html.Strings[uIndice + 1] = 'class') and
      (tokens_html.Strings[uIndice + 2] = '=') and
      (tokens_html.Strings[uIndice + 3] = '"resultados"') and
      (tokens_html.Strings[uIndice + 4] = '>') then
    begin
      // Se encontrarmos o início, devemos apontar após o tag: '>'
      Inc(uIndice, 5);
      break;
    end;

    // Vamos percorrer um token por vez, até encontrar o token inicial.
    Inc(uIndice, 1);
  end;

  // Se uIndice é maior que 'uTotal_de_Tokens', quer dizer, que não foi encontrado
  // Nenhum tokens de início de resultado.
  if uIndice > uTotal_de_Tokens then
  begin
    strErro := Format('Os tokens não foram localizados: ' +
      QuotedStr('%s') + QuotedStr('%s') + QuotedStr('%s') +
      QuotedStr('%s'), ['<div', 'class', '=', '"resultados"']);
    Exit(False);
  end;

  // Dentro de '<div class="resultados"' haverá vários jogos, para termos
  // certeza até onde iremos iremos percorrer até encontrar o tag de fechamento
  // correspondente.
  // Vamos localizar o tag '</div>' que corresponde ao tag <div class = "resultados">
  // Como assim, estamos apontando após '<div' devemos fazer uIndice, apontar para
  // a posição de '<div'

  uTag_Div_Fechamento_Indice := 0;

  // Se não encontrado o tag de fechamento, sair então.
  // O índice inicial é igual a -5, pois devemos começar do token '<div'
  if not tag_abre_e_fecha(tokens_html, 'div', uIndice - 5, tokens_html.Count -1,  uTag_Div_Fechamento_Indice) then
  begin
     strErro := 'Tag de fechamento ''</div>'' não encontrado, que corresponderia ' +
                'ao tag de início: ''<div class="resultados"''';
     Exit(false);
  end;

  // Aqui, uIndice após após o token '>', de


  // Se o intervalo inicial e final não existe, o servidor retorna uma mensagem no formato abaixo:
  // <div class="item_busca">Nenhum resultado encontrado!</div>'
  // Então devemos verificar isto antes, pois se não há nenhum jogo, informar com um erro.
  if (tokens_html[uIndice + 0] = '<div') and
     (tokens_html[uIndice + 1] = 'class') and
     (tokens_html[uIndice + 2] = '=') and
     (tokens_html[uIndice + 3] = '"item_busca"') and
     (tokens_html[uIndice + 4] = '>') and
     (tokens_html[uIndice + 5] = 'Nenhum resultado encontrado!') and
     (tokens_html[uIndice + 6] = '</div>') then
     begin
        strErro := 'Nem resultado encontrado para o intervalo de jogo solicitado!!!';
        Exit(False);
     end;


  // O próximo tag que segue é:
  // <div class = "item_busca" >
  //      Resultado do sorteio
  //      <strong>Keno Minas</strong>
  //      de número
  //      <strong>999999</strong>
  // <div

  // Aqui, uIndice deve apontar para o tag '<div'
  // Sempre, iremos verificar se há alguns do tokens e retornar o erro.
  if not ((tokens_html[uIndice + 0] = '<div') and
         (tokens_html[uIndice + 1] = 'class') and
         (tokens_html[uIndice + 2] = '=') and
         (tokens_html[uIndice + 3] = '"item_busca"') and
         (tokens_html[uIndice + 4] = '>') and
         (tokens_html[uIndice + 5] = 'Resultado do sorteio') and
         (tokens_html[uIndice + 6] = '<strong>') and
         // O campo na posição uIndice + 7, refere ao jogo, iremos verificar
         // depois, pois este campo é variável.
         (tokens_html[uIndice + 8] = '</strong>') and
         (tokens_html[uIndice + 9] = 'de número') and
         (tokens_html[uIndice + 10] = '<strong>') and
         // O campo na posição uIndice + 11, refere-se ao número do sorteio do jogo.
         // Este campo é variável, será verificado posteriormente.
         (tokens_html[uIndice + 12] = '</strong>') and
         (tokens_html[uIndice + 13] = '</div>')) then
  begin
     // TODO: Verificar uIndice + 9 = Saiu no arquivo outros caracteres.

     strErro := 'Erro, após o tag de fechamento do tag ''<div class="resultados">''' +
               'Era esperado os campos do tag: ''<div class="item_busca">''';
     Exit(False);
  end;

  // O campo na posição 'uIndice + 7', indica o nome do jogo.
  strJogo := tokens_html[uIndice + 7];
  if not jogo_valido(strJogo) then
     Exit(False);

  if not gravar_cabecalho(strJogo) then
     Exit(False);

  // Em seguida, cada informação do jogo, fica entre os tags: '<div class="result-item">' e '</div>'
  // Pode haver mais de um jogo, então haverá mais de um tag conforme descrito acima.
  // Vamos fazer uIndice apontar para o token '<div'.
  Inc(uIndice, 14);

  while uIndice < uTag_Div_Fechamento_Indice do
  begin
    // Vamos verificar se os tags começam com '<div class="result-item">'
    if not((tokens_html[uIndice] = '<div') and
       (tokens_html[uIndice + 1] = 'class') and
       (tokens_html[uIndice + 2] = '=') and
       (tokens_html[uIndice + 3] = '"result-item"') and
       (tokens_html[uIndice + 4] = '>')) then
       begin
          strErro := 'Era esperado os tags: ''<div class="result_item" >''';
          Exit(False);
       end;

    // Se chegamos aqui, quer dizer que o tag inicial existe, devemos encontrar
    // o tag de fechamento.
    // Se o acharmos, devemos ir para o próximo tag dentro deste tag.
    tag_fim_result_item := 0;
    if not tag_abre_e_fecha(tokens_html, 'div', uIndice, uTag_Div_Fechamento_Indice, tag_fim_result_item) then
    begin
       strErro := 'Tag div correspondente de fechamento para o tag inicial: ' +
                  '''<div class="result_item" >'' não localizado.';
       Exit(False);
    end;

    // Aponta para o ínicio do tag: '<span'
    Inc(uIndice, 5);

    // Verifica se o próximo tag é:
    if not ((tokens_html[uIndice] = '<span') and
           (tokens_html[uIndice + 1] = 'class') and
           (tokens_html[uIndice + 2] = '=') and
           (tokens_html[uIndice + 3] = '"num_id"') and
           (tokens_html[uIndice + 4] = '>') and
           // Na posição uIndice + 5, fica a informação
           // do número do concurso, data, e hora, iremos analisar depois.
           (tokens_html[uIndice + 6] = '</span>')) then
    begin
       strErro := Format('Erro, índice: %d, era esperado os tokens: ' +
                  '''<span class = "num_id">'' .. ''</span>''.', [uIndice]);
       Exit(False);
    end;

    // O token na posição uIndice + 5, contém a informação do
    // número do concurso, data e hora, iremos pegar somente
    // o número do concurso e a data, a hora não é necessária, ainda.
    // Então, iremos verificar cada campo.
    concurso_data_hora := LowerCase(tokens_html[uIndice + 5]);

    // Se não começa, retorna falso e not inverte para true.
    if not AnsiStartsStr('número: ', concurso_data_hora) then
    begin
       strErro := 'Erro, índice: ' + IntToStr(uIndice + 5) + ', era o token ' +
                  'começando com ''Número: ''';
       Exit(False);
    end;

    // Vamos pegar o número do concurso.
    concurso_data_hora := AnsiMidStr(concurso_data_hora, Length('número: ') + 1,
                          Length(concurso_data_hora));
    concurso_data_hora := Trim(concurso_data_hora);

    // Após vem o número do concurso, devemos procurar um espaço após.
    iEspaco_Posicao := AnsiPos(' ', concurso_data_hora);

    if iEspaco_Posicao = 0 then
    begin
       strErro := 'Erro, índice ' + IntToStr(uIndice + 5) + ', número de concurso inválido.';
       Exit(False);
    end;

    numero_do_concurso := AnsiLeftStr(concurso_data_hora, iEspaco_Posicao -1);
    numero_do_concurso := Trim(numero_do_concurso);

    try
       StrToInt(numero_do_concurso);
    except
		      on exc:Exception do
		      begin
		        strErro := 'Erro, índice: ' + IntTostr(uIndice + 5) + exc.Message;
		        Exit(False);
		      end;
    end;

    // Vamos adicionar o nome do jogo:
    jogo_resultado.Add(strJogo);

    // Vamos adicionar o número do concurso;
    jogo_resultado.Add(numero_do_concurso);

    // Deleta o número do concurso no string 'concurso_data_hora'.
    Delete(concurso_data_hora, 1, iEspaco_Posicao);

    concurso_data_hora := Trim(concurso_data_hora);

    // Vamos verificar se começa com a palavra 'Data:'
    // Observe que estamos comparando em minúsculo, pois, convertermos
    // assim a variável concurso_data_hora em minúscula.
    if not AnsiStartsStr('data:', concurso_data_hora) then
    begin
       strErro := 'Erro, índice ' + IntToStr(uIndice + 5) + ', era esperado a palavra ' +
                  '''Data:'' após o número do concurso do jogo.';
       Exit(False);
    end;

    // A data e hora deve ser separada por um espaço em branco.
    strData_Hora := AnsiMidStr(concurso_data_hora, 6, Length(concurso_data_hora));

    // Vamos verificar se a data é válida.
    if not Validar_Data_Hora(strData_Hora, strData, strHora) then
    begin
       strErro := 'Data inválida.';
       Exit(False);
		end;

    // Temos a data e hora, guardar esta informação
    jogo_resultado.Add(strData);


    // Vamos apontar para o próximo token
    Inc(uIndice, 7);
    if not((tokens_html[uIndice] = '<div') and
       (tokens_html[uIndice + 1] = 'class') and
       (tokens_html[uIndice + 2] = '=') and
       (tokens_html[uIndice + 3] = '"bolas"') and
       (tokens_html[uIndice + 4] = '>')) then
       begin
          strErro := Format('Erro, índice: %d, era esperado os tags: ' +
                     '''<div class = "bolas" >''.', [uIndice]);
          Exit(False);
       end;

    // Vamos localizar o tag de fechamento, referente ao tag '<div class = "bolas">'
    tag_fim_class_bolas := 0;
    if not tag_abre_e_fecha(tokens_html, 'div', uIndice, tag_fim_result_item, tag_fim_class_bolas) then
    begin
       strErro := Format('Erro, índice: %d, tag de fechamento correspondente' +
                  ' a ''<div class="bolas">'' não localizado.', [uIndice]);
       Exit(False);
    end;

    // No loop abaixo, iremos percorrer até chegar ao token de índice tag_fim_class_bolas
    // Para cada número sorteado, há os tokens abaixo, onde 99, sempre um número qualquer.
    // <span class = "bolao" >
    //       <p>99</p>
    // </span>

    // Vamos apontar para o primeiro token, que é '<span'.
    Inc(uIndice, 5);

    while uIndice < tag_fim_class_bolas do
    begin
      // Entre os tags '<div class="bolas">' and '</div>', há duas formas:
      // Jogo que é diferente de 'Multiplix', tem os tags seguintes:
      // <span class = "bolao" >
      //       <p>999</p>
      // </span>

      // E no caso do multiplix, além do formato cima para os números das bolas,
      // o jogo tem mais uma tag conforme layout abaixo:
      // <div class = "pedra bolao" >
      //      <span class="esmeralda_int" title="Esmeralda"> </span>
      //      <span class="name">Esmeralda</span>
      // </div>
      // Conforme contéudo html, esta forma deve ser a última dentro do tag
      // <div class="bolas">

      if strJogo = 'INTRALOT_MULTIPLIX' then begin
         // Quando a último tag estiver no final, no caso, do jogo multiplix
         // será informado, o tipo da pedra, rubi, esmeralda e assim por diante.
         // Neste caso, haverá 22 tokens, o primeiro token começa em 0 e o último
         // termina em 21, então após este estaremos depois do fim do tag, ou seja
         // estaremos no tag de fechamento da tag '<div class = "bolas">
         if uIndice + 22 = tag_fim_class_bolas then
         begin
            if not (
               (tokens_html[uIndice + 0] = '<div') and
               (tokens_html[uIndice + 1] = 'class') and
               (tokens_html[uIndice + 2] = '=') and
               (tokens_html[uIndice + 3] = 'pedra bolao') and
               (tokens_html[uIndice + 4] = '>') and
               (tokens_html[uIndice + 5] = '<span') and
               (tokens_html[uIndice + 6] = 'class') and
               (tokens_html[uIndice + 7] = '=') and
               // O ítem da posição uIndice + 8 varia, será analisado posteriormente.
               (tokens_html[uIndice + 9] = 'title') and
               (tokens_html[uIndice + 10] = '=') and
               // O ítem da posição uIndice + 11 varia, será analisado posteriormente.
               (tokens_html[uIndice + 12] = '>') and
               (tokens_html[uIndice + 13] = '</span>') and
               (tokens_html[uIndice + 14] = '<span') and
               (tokens_html[uIndice + 15] = 'class') and
               (tokens_html[uIndice + 16] = '=') and
               (tokens_html[uIndice + 17] = '"name"') and
               (tokens_html[uIndice + 18] = '>') and
               // O ítem da posição uIndice + 19 varia, será analisado posteriormente.
               // Este será o valor que será guardado.
               (tokens_html[uIndice + 20] = '</span>') and
               (tokens_html[uIndice + 21] = '</div>')) then
               begin
                  strErro := 'Erro, índice ' + IntToStr(uIndice) + ' no layout para ' +
                             'definir quais dos símbolos utilizar: ' + #13#10 +
                             'Rubi, Esmeralda, Diamante ou Topazio.';
                  Exit(false);
							 end;

               // Verifica se existe um dos símbolos.
               pedra_preciosa_simbolo := Trim(LowerCase(tokens_html[uIndice+19]));
               if (pedra_preciosa_simbolo <> 'rubi') and (pedra_preciosa_simbolo <> 'esmeralda') and
                  (pedra_preciosa_simbolo <> 'diamante') and (pedra_preciosa_simbolo <> 'topazio') then
                     begin
                           strErro := 'Era esperado um dos símbolos: Rubi, Esmeralda, Diamante ou Topazio.';
                           Exit(False);
										 end;

               // Adiciona símbolo localizado.
               jogo_resultado.Add(pedra_preciosa_simbolo);
			   end;
			end;

      if not((tokens_html[uIndice] = '<span') and  (tokens_html[uIndice + 1] = 'class') and
         (tokens_html[uIndice + 2] = '=')     and  (tokens_html[uIndice + 3] = '"bolao"') and
         (tokens_html[uIndice + 4] = '>')     and  (tokens_html[uIndice + 5] = '<p>') and
         // O token na posição uIndice + 6 representa o número da bola.
         (tokens_html[uIndice + 7] = '</p>') and   (tokens_html[uIndice + 8] = '</span>')) then
         begin
            strErro := Format('Erro, índice %s, era esperado os tokens: ' + #13#10 +
                       '<span class="bolao">' + #13#10 +
                       '<p>999</p>' + #13#10 +
                       '</span>' + #13#10 +
                       'onde 999, representa um número qualquer.', [uIndice]);
            Exit(False);
         end;

         try
            uBola_Numero := StrToInt(tokens_html[uIndice + 6]);
         except
           On exc: Exception do
           begin
             strErro := 'Erro, índice: ' + IntToStr(uIndice + 6) + exc.Message;
             Exit(False);
           end;
         end;

         jogo_resultado.Add(IntToStr(uBola_Numero));
         Inc(uIndice, 9);
    end;

    // Acabamos de processar todas as bolas do jogo, guardar na variável de instância
    // da classe.
    strTexto_Resultado := jogo_resultado[0];
    for iA := 1 to jogo_resultado.Count - 1 do begin
      strTexto_Resultado := strTexto_Resultado + ';' + jogo_resultado[iA];
		end;

    // Guarda a lista de resultados do jogo.
    lista_de_resultados.Add(strTexto_Resultado);

    // Apagar lista temporária.
    jogo_resultado.Clear;


    // Até aqui, uIndice aponta para a mesma posição de tag_fim_class_bolas
    // tag_fim_class_bolas corresponde ao tag de fechamento do tag de abertura
    // <div class="bolas">
    uIndice := tag_fim_class_bolas + 1;

    // Agora, após incrementarmos, apontará para '</div>' da tag
    // <div class="bolao">
    // Também devemos incrementar para apontar após '</div>'.
    Inc(uIndice, 1);
  end;

  if not Assigned (resultado_dos_jogos) then
     resultado_dos_jogos := TStrings(TStringList.Create);

  resultado_dos_jogos.Clear;
  resultado_dos_jogos.AddStrings(lista_de_resultados);

  lista_de_resultados.Clear;
  FreeAndNil(lista_de_resultados);
  Exit(True);

end;


function Tfb_Intralot_Resultados.intervalo_valido_das_bolas(jogo_tipo: string; bola_numero: integer): boolean;
begin
  case LowerCase(jogo_tipo) of
    'intralot_minas_5': Result := (bola_numero >= 1) and (bola_numero <= 34);
    'intralot_loto_minas': Result := (bola_numero >= 1) and (bola_numero <= 38);
    'intralot_keno_minas': Result := (bola_numero >= 1) and (bola_numero <= 80);
	end;

end;



// Cada jogo no contéudo html tem uma representação ao visualizar o html no navegador.
// Entretanto, ao gravar no banco deve estar conforme o layout no banco de dados.
// Por exemplo, o jogo 'Keno Minas', tem a representação: 'INTRALOT_KENO_MINAS'
function TFb_Intralot_Resultados.jogo_valido(var strJogo: string): boolean;
begin
  case LowerCase(strJogo) of
    'keno minas': strJogo := 'INTRALOT_KENO_MINAS';
    'loto minas': strJogo := 'INTRALOT_LOTO_MINAS';
    'multplix'  : strJogo := 'INTRALOT_MULTIPLIX';
    'totolot'   : strJogo := 'INTRALOT_TOTOLOT';
    'minas 5'   : strJogo := 'INTRALOT_MINAS_5';
    else
      begin
        strErro := 'Jogo inválido: ' + strJogo;
        Exit(False);
			end;
	end;
  Exit(True);
end;

{
    Esta função verificar se um tag de abertura, tem seu tag respectivo de fechamento.
    Por exemplo, se analisarmos o tag '<div>', devemos localizar o tag '</div>',

    A função funciona assim:
    Um variável é atribuído o valor 1, pois temos um tag, por exemplo, '<div>'
    Ao percorrermos a lista de tokens, ao encontrarmos o tag de abertura:
    '<div>' ou '<div' seguido de '>', incrementaremos tal variável em 1.
    Ao encontrarmos o tag de fechamento decrementaremos tal variável em 1.

    Se durante percorrermos sequencialmente a lista de tokens, a variável torna-se zero, quer dizer
    que o tag de fechamento correspondente foi localizado. Devemos retornar da
    função com o valor 'True' e Indicar na variável uIndice_Tag, a posição baseada
    em zero, do tag de fechamento.

    Os parâmetros são:
    tokens_html:                  O token a analisar.
    strIdentificador_Tag:         O identificador do tag a localizar.
    uIndice_Inicio:               O índice em tokens_html, em que a pesquisa começará.
    uIndice_Fim:                  O índice final em tokens_html, baseado em zero, em que a pesquisa terminará.
    uIndice_Tag:                  O índice em tokens_html, que o tag de fechamento correspondente foi localizado.

}


function Tfb_Intralot_Resultados.Tag_Abre_e_Fecha(tokens_html: TStrings; strIdentificador_Tag: string;
  uIndice_Inicio: integer; uIndice_Fim: integer; out uIndice_Tag: integer): boolean;
var
  iA: integer;
  uTokens_Quantidade: integer;
  iTag_Div_Qt: integer;
begin
  // Vamos validar a informação entrada pelo usuário nos campos:
  // uIndice_Inicio e uIndice_Fim.

  if uIndice_Fim < uIndice_Inicio then begin
     strErro := 'Índice final menor que índice inicial.';
     Exit(False);
	end;

  if uIndice_Inicio < 0 then begin
     strErro := 'Índice inicial menor que zero.';
     Exit(False);
	end;

  // uIndice_Fim é baseado em zero, então deve ser menor que count -1.
  if uIndice_Fim > tokens_html.Count then begin
     strErro := 'Índice final maior que quantidade de ítens em tokens_html.';
     Exit(False);
	end;

  // iA, apontará para a posição que começaremos a escanear,
  // que corresponde a uIndice_Inicio;
  iA := uIndice_Inicio;
  uTokens_Quantidade := uIndice_Fim;

  // Deve haver um balanceamento entre todos os tags html
  // Neste caso, estamos verificando somente o tag '<div'
  iTag_Div_Qt := 0;

  while iA <= uTokens_Quantidade do
  begin

    if tokens_html.Strings[iA] = '<div' then
    begin
      // Quando em html, encontramos um tag, iniciando, por exemplo
      // '<div', isto quer dizer, que entre '<div' e '>', há propriedades
      // na forma propriedade=valor, então devemos localizar o token
      // '>', mas entre o token '<div' e '>', não pode haver token
      // nestes formatos: '<teste', '</teste>' e '<teste>'
      Inc(iA);

      while iA <= uTokens_Quantidade do
      begin
        // Temos que utilizar esta condição primeiro
        // Senão, quando entrar na condição abaixo dará um erro
        // pois, na segunda condição abaixo, estamos verificando
        // as extremidades esquerda e direita do string a procura
        // do caractere '<', e se o token for um único caractere,
        // a condição será satisfeita.
        if tokens_html.Strings[iA] = '>' then
        begin
          Inc(iTag_Div_Qt);
          Break;
        end;

        if (AnsiStartsStr('<', tokens_html.Strings[iA]) = True) or
          (AnsiEndsStr('>', tokens_html.Strings[iA]) = True) or
          ((AnsiStartsStr('<', tokens_html.Strings[iA]) = True) and
          (AnsiEndsStr('>', tokens_html.Strings[iA]) = True)) then
        begin

          strErro := 'Propriedade do tag ''<div'' inválida ' +
            'provavelmente, faltou o caractere ' +
            'antes da propriedade.';
          Exit(False);

        end;
        Inc(iA);
      end;
    end;

    if tokens_html.Strings[iA] = '<div>' then
    begin
      Inc(iTag_Div_qt);
    end;
    if tokens_html.Strings[iA] = '</div>' then
    begin
      Dec(iTag_Div_Qt);
    end;

    // Se igual a zero, quer dizer, que encontramos nosso nosso
    // tag de fechamento.
    if iTag_Div_Qt = 0 then
    begin
      uIndice_Tag := iA;
      Exit(true);
    end;

    // Ao sair do loop, iA, sempre apontará para o tag de fechamento,
    // pois, se 'iTag_Div_Qt' é igual a zero, não haverá incremento
    // da variável iA.
    Inc(iA);
  end;

  if iTag_Div_Qt <> 0 then
     Result := false;

end;

function Tfb_Intralot_Resultados.Validar_Hora(strData_Hora: string): boolean;
var
			hora_campo: Integer;
			iDois_Pontos: SizeInt;
			strHora: String;
begin
  if strData_Hora = '' then
  begin
    strErro := 'Formato de tempo inválido, nenhum tempo fornecido.';
    Exit(False);
	end;




end;


// Validar o campo data e hora e se informação estiver válida, retorna data e hora
// nas variáveis strData e strHora, respectivamente.
// strData_Hora deve estar neste formato: DD/MM/YYYY HH:NN
//

function TFB_Intralot_Resultados.Validar_Data_Hora(strData_Hora: string; var strData: string;
  var strHora: string): boolean;
var
  iVirgula: SizeInt;
  iDia: Integer;
  iMes: Integer;
  iAno: Integer;
  bAno_Bissexto: Boolean;
begin
     if strData_Hora = '' then
     begin
       strErro := 'Data inválida.';
		 end;

     // O valor para a propriedade 'data' deve está formato conforme abaixo:
     // 31/10/2015 20:00

     // Os números das datas, dia e mês, sempre formatados com dois dígitos.
     // Vamos analisar cada caractere.
     // Primeiro, iremos verificar se são só números válidos e a barra.

     iVirgula := pos('/', strData_Hora);
     if iVirgula <= 1 then begin
        strErro := 'Formato de data e hora inválido: ''/'' ausente.';
        Exit(false);
     end;

     try
     iDia := StrToInt(AnsiLeftStr(strData_Hora, iVirgula - 1));

     // Vamos apontar o string após a barra depois do dia.
     strData_Hora := AnsiMidStr(strData_Hora, iVirgula + 1, Length(strData_Hora));

     iVirgula := pos('/', strData_Hora);
     if iVirgula <= 1 then begin
        strErro := 'Formato de data e hora inválido: ''/'' ausente.';
        Exit(false);
     end;

     iMes := StrToInt(AnsiLeftStr(strData_Hora, iVirgula - 1));

     // Vamos apontar o string após a barra depois do mês.
     strData_Hora := AnsiMidStr(strData_Hora, iVirgula + 1, Length(strData_Hora));

     iVirgula := pos(' ', strData_Hora);

     if iVirgula <= 1 then begin
        strErro := 'Formato de data e hora inválido: '','' ausente.';
        Exit(false);
     end;

     iAno := StrToInt(AnsiLeftStr(strData_Hora, iVirgula - 1));

     // Vamos apontar o string para depois do espaço.
     strData_Hora := AnsiMidSTr(strData_Hora, iVirgula + 1, Length(strData_Hora));


     // Se está fora da faixa é inválido.
     if  (iDia in [1..31]) = false then begin
        strErro := 'Formato de Data inválido: ' +
                   'Dia não está no intervalo de 1 a 31.';
        Exit(false);
     end;

     // Vamos verificar se a data é válida.
     // Os meses que terminam com 30 são:
     // Abril, Junho, Setembro, Novembro
     // Se o dia for 31, e o mês for abril, junho, setembro ou novembro.
     // o formato de data está inválido.

     if (iDia = 31) and (iMes in [2, 4, 6, 9, 11]) then begin
        strErro := 'Formato de data invalido: ' + #10#13 +
                   'O último dia do mês de Abril, Junho, Setembro e ' + #10#13 +
                   'Novembro, é 30, entretanto, o dia fornecido é 31.';
        Exit(False);
     end;

     // Se o mês é fevereiro e o dia é maior que 29, indicar um erro.
     if (iDia > 29) and (iMes = 2) then begin
        strErro := 'Formato de data inválido: Mês de fevereiro termina em 28, ' +
                   'ou 29, se bissexto, entretanto, o dia fornecido é maior que ' +
                   '29.';
        Exit(false);
     end;

     // Vamos verificar, se o ano não for bissexto e o mês de fevereiro é 29
     // está errado, então.
     bAno_Bissexto := false;

     if ((iAno mod 4 = 0) and (iAno mod 100 <> 1)) or
        (iAno mod 400 = 0) then begin
           bAno_Bissexto := true;
     end;

     if (iDia = 29) and (bAno_Bissexto = false) and (iMes = 2) then begin
        strErro := 'Formato de data inválido: Dia é igual a ''29'' de ''fevereiro''' +
                   ' mas ano não é bissexto.';
        Exit(False);
     end;

     except
       // Se strToInt dar uma exceção indicando que o string não é um número
       // devemos retornar falso.
       On exc: Exception do begin
             strErro := exc.Message;
             Exit(false);
       end;
     end;

     // Vamos retornar as informações nas variáveis strData, strHora
     strData := Format('%d/%d/%d', [iDia, iMes, iAno]);
     strHora := '';

    Result:= true;
end;

end.
