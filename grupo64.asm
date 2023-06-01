; grupo 64
; Manuel Fernandes ist1106410
; Tomas Candido ist1106470


; **********************************************************************
; * painel da nave
; **********************************************************************

;ecra
COMANDOS                 EQU 6000H               ; endereço de base dos comandos do MediaCenter

DEFINE_LINHA             EQU COMANDOS + 0AH      ; endereço do comando para definir a linha
DEFINE_COLUNA            EQU COMANDOS + 0CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL             EQU COMANDOS + 12H      ; endereço do comando para escrever um pixel
APAGA_AVISO              EQU COMANDOS + 40H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ               EQU COMANDOS + 02H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU COMANDOS + 48H      ; endereço do comando para selecionar uma imagem de fundo (42H, IMAGEM)(48H, VIDEO)
CONTUA_CENARIO           EQU COMANDOS + 60H      ; continua o video
TOCA_SOM                 EQU COMANDOS + 5AH      ; endereço do comando para tocar um som

N_LINHAS                 EQU  32                 ; número de linhas do ecrã (altura)


; cor dos pixels usados em ARGB
CINZA_ESC                EQU 0F222H
CINZA_TRANS              EQU 0F555H          
VERDE_ESC                EQU 0F070H
VERMELHO                 EQU 0FF00H
AZUL                     EQU 0F0AFH
AMARELO                  EQU 0FFD0H
VERDE_CLA                EQU 0F0D0H


;boneco
LINHA                    EQU  0          ; linha do boneco 
COLUNA                   EQU  0          ; coluna do boneco 

ATRASO                   EQU 400H        ; atraso para limitar a velocidade de movimento do boneco

LARGURA                  EQU 5           ; largura do boneco
ALTURA                   EQU 5
COR_ASTEROIDE            EQU 0FF0CH      ; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)


; **********************************************************************
; * teclado
; **********************************************************************

DISPLAYS                 EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN                  EQU 0C000H  ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL                  EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
MASCARA                  EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
TECLA_ASTEROIDE          EQU 1       ; tecla na segunda coluna do teclado (tecla D)
LINHA_TECLA              EQU 1
TECLA_AUMENTA            EQU 1
TECLA_DESCRESCE          EQU 2
LINHA_ALTERA             EQU 4

; **********************************************************************
; * dados
; **********************************************************************

PLACE      1000H
pilha:
    STACK 100H 

SP_inicial:


DEF_TECLA:
    WORD        0

DEF_BONECO:                 ; tabela que define o boneco (cor, largura, pixels)
    WORD        LARGURA
    WORD        ALTURA
    WORD        0, COR_ASTEROIDE, COR_ASTEROIDE, COR_ASTEROIDE, 0
    WORD        COR_ASTEROIDE, 0, COR_ASTEROIDE, 0, COR_ASTEROIDE       ; # # #   as cores podem ser diferentes de pixel para pixel
    WORD        COR_ASTEROIDE, COR_ASTEROIDE, COR_ASTEROIDE, COR_ASTEROIDE, COR_ASTEROIDE
    WORD        0, COR_ASTEROIDE, 0, COR_ASTEROIDE, 0
    WORD        COR_ASTEROIDE, 0, COR_ASTEROIDE, 0, COR_ASTEROIDE

; **********************************************************************
; * Código
; **********************************************************************
PLACE      0

cod_princ:
    MOV SP, SP_inicial

    MOV  [APAGA_AVISO], R11  ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R11   ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
    MOV R11, 0
    MOV  [SELECIONA_CENARIO_FUNDO], R11  ; seleciona o cenário de fundo


    MOV  R2, LINHA              ; linha do boneco inicial
    MOV  R3, COLUNA             ; coluna do boneco inicial
    MOV  R8, DEF_BONECO         ; endereço da tabela que define o boneco


    MOV R5, 23                  ; linha da sonda inicial
    MOV R6, 31                  ; coluna da sonda

    MOV R7, 1                   ; valores inciais a ser mostrado nos displyas (100)
    SHL R7, 8


    CALL pinta_contorno             ; escreve o contorno do painel  
    CALL painel_de_instrumentos     ; escreve o painel de instrumentos
    CALL escreve_amarelo
    CALL escreve_vermelho
    CALL escreve_azul
    CALL escreve_circulo_verde_esc
    CALL detalhe

    CALL desenha_boneco
    CALL desenha_sonda

    CALL mostra_display

    verifica_tecla:
        MOV R4, [DEF_TECLA]
        MOV R10, MASCARA
        CALL teclado

        CMP R1, R4
        JZ verifica_tecla
        MOV [DEF_TECLA], R1
        MOV R0, R1
        SHR R0, 4               ; obter a linha da tecla premida 
        AND R1, R10             ; obter a coluna da tecla premida
        CMP R0, LINHA_TECLA
        JNZ tecla_display
        CMP R1, TECLA_ASTEROIDE
        JNZ tecla_sonda
        MOV R9, 1               ; som com número 0
        MOV [TOCA_SOM], R9      ; comando para tocar o som
        CALL apaga_boneco
        ADD R2, 1               ; incrementa a linha do asteroide
        ADD R3, 1               ; incrementa a coluna do asteroide
        CALL desenha_boneco
        JMP verifica_tecla

        tecla_sonda:
            CALL apaga_sonda
            SUB R5, 1           ; faz com que a sonda suba, decrementando a sondas
            CALL desenha_sonda
            JMP verifica_tecla

        tecla_display:
            CMP R0, LINHA_ALTERA
            JNZ verifica_tecla
            CMP R1, TECLA_AUMENTA
            JNZ diminui
            CALL aumenta_display
            JMP verifica_tecla

            diminui:
                CALL diminui_display
                JMP verifica_tecla


fim:
    JMP fim 


teclado:
    PUSH R0
    PUSH R2
    PUSH R3
    PUSH R5
    PUSH R6
    PUSH R7

    ; inicializações
    MOV R2, TEC_LIN      ; endereço do periférico das linhas
    MOV R3, TEC_COL      ; endereço do periférico das colunas
    MOV R5, MASCARA      ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
    MOV R1, 0

    espera_tecla:        ; neste ciclo espera-se até uma tecla ser premida
        MOV R6, 1        ; valor inicial para testar a primeira linha
        MOV R7, 1        ; contador de linhas

    verifica_linha:
        MOVB [R2], R6    ; escrever no periférico de saída (linhas)
        MOVB R0, [R3]    ; ler do periférico de entrada (colunas)
        AND R0, R5       ; elimina bits para além dos bits 0-3
        CMP R0, 0        ; há tecla premida?
        JNZ mostra_tecla ; se houver tecla premida, mostra a linha e a coluna da tecla

        ADD R7, 1        ; incrementa o contador de linhas
        CMP R7, 4        ; verifica se todas as linhas foram verificadas
        JGT sair_teclado ; se todas as linhas foram verificadas e nenhuma tecla foi premida, repete

        SHL R6, 1        ; move para a próxima linha
        JMP verifica_linha

    mostra_tecla:
        MOV R1, R7       ; coloca o valor da linha no registro R1
        SHL R1, 4        ; coloca linha no nibble high
        OR R1, R0        ; junta coluna (nibble low)

    sair_teclado:

    POP R7
    POP R6
    POP R5
    POP R3
    POP R2
    POP R0

    RET 


pinta_contorno:
    PUSH R1 
    PUSH R2                    ; guarda os registos alterados por esta rotina
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    MOV R1, 24                 ; linha corrente
    MOV R6, 21
    MOV  R5, N_LINHAS
    MOV  R2, 24                 ; coluna corrente
    MOV  R4, 40
    eee_proxima_linha:
        CALL escreve_linhas      ; escreve os pixels na linha corrente
        ADD  R1, 1              ; próxima linha
        CMP R2, R6              ; se nao chegou ao tamanho desejado salta para corrigir os valores da coluna
        JNZ ajustess 
        continuacao:
        CMP  R1, R5             ; chegou ao fim?
        JLT  eee_proxima_linha
        POP R6
        POP R5
        POP R4
        POP R3
        POP R2
        POP R1
        RET

        ajustess:
        SUB R2, 1
        ADD R4, 1
        JMP continuacao

    escreve_linhas:
        PUSH R2
        PUSH R3
        
        ell_proximo_pixel:
        CALL escreve_pixels       ; escreve o pixel na coluna corrente
        ADD  R2, 1               ; próxima coluna
        CMP  R2, R4              ; chegou ao fim?
        JLT  ell_proximo_pixel
        POP  R3
        POP  R2
        RET

    escreve_pixels:
        PUSH R3
        MOV R3, CINZA_ESC
        MOV  [DEFINE_LINHA], R1     ; seleciona a linha
        MOV  [DEFINE_COLUNA], R2    ; seleciona a coluna
        MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
        POP R3
        RET
    RET

painel_de_instrumentos:
    escreve_ecra:
        PUSH R1
        PUSH R2                     
        PUSH R3
        PUSH R4
        PUSH R5
        PUSH R6
        MOV R1, 25                  ; linha corrente
        MOV R6, 22                  ; coluna inicial
        MOV  R5, N_LINHAS           ; linha maxima
        MOV  R2, 24                 ; coluna corrente
        MOV  R4, 40
            ee_proxima_linha:
            CALL escreve_linha      ; escreve os pixels na linha corrente
            ADD  R1, 1              ; próxima linha
            CMP R2, R6              ; se nao chegou ao tamanho desejado salta para corrigir os valores da coluna
            JNZ ajustes 
            continua:
            CMP  R1, R5             ; chegou ao fim?
            JLT  ee_proxima_linha
            POP R6
            POP R5
            POP R4
            POP R3
            POP R2
            POP R1
            RET

        ajustes:
            SUB R2, 1
            ADD R4, 1
            JMP continua

    escreve_linha:
        PUSH R2
        PUSH R3
        
            el_proximo_pixel:
            CALL escreve_pixel       ; escreve o pixel na coluna corrente
            ADD  R2, 1               ; próxima coluna
            CMP  R2, R4              ; chegou ao fim?
            JLT  el_proximo_pixel
            POP  R3
            POP  R2
            RET

    escreve_pixel:
        PUSH R3
        MOV R3, CINZA_TRANS
        MOV  [DEFINE_LINHA], R1     ; seleciona a linha
        MOV  [DEFINE_COLUNA], R2    ; seleciona a coluna
        MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
        POP R3
        RET

    RET


    escreve_amarelo:
        PUSH R1                     ; guarda os registos alterados por esta rotina
        PUSH R3
        PUSH R5
        PUSH R6
        MOV R1, 27                 ; linha corrente
        MOV R6, 25                 ; coluna corrente
        MOV R5, 31               
            ee_proxima_linha_amarelo:
            CALL escreve_linha_amarelo      ; escreve os pixels na linha corrente
            ADD  R1, 1                  ; próxima linha
            CMP  R1, R5                 ; chegou ao fim?
            JLT  ee_proxima_linha_amarelo
            POP R6
            POP R5
            POP R3
            POP R1
            RET

        escreve_linha_amarelo:
            PUSH R3
            CALL escreve_pixel_amarelo      ; escreve o pixel na coluna corrente
            POP  R3
            RET

        escreve_pixel_amarelo:
            PUSH R3
            MOV R3, AMARELO
            MOV  [DEFINE_LINHA], R1     ; seleciona a linha
            MOV  [DEFINE_COLUNA], R6    ; seleciona a coluna
            MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
            POP R3
            RET

    escreve_vermelho:
        PUSH R1                     ; guarda os registos alterados por esta rotina
        PUSH R3
        PUSH R5
        PUSH R6
        MOV R1, 27                 ; linha corrente
        MOV R6, 27                 ; coluna corrente
        MOV R5, 31               
            ee_proxima_linha_vermelho:
            CALL escreve_linha_vermelho      ; escreve os pixels na linha corrente
            ADD  R1, 1                  ; próxima linha
            CMP  R1, R5                 ; chegou ao fim?
            JLT  ee_proxima_linha_vermelho
            POP R6
            POP R5
            POP R3
            POP R1
            RET

    escreve_linha_vermelho:
        PUSH R3
        CALL escreve_pixel_vermelho      ; escreve o pixel na coluna corrente
        POP  R3
        RET

    escreve_pixel_vermelho:
        PUSH R3
        MOV R3, VERMELHO
        MOV  [DEFINE_LINHA], R1     ; seleciona a linha
        MOV  [DEFINE_COLUNA], R6    ; seleciona a coluna
        MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
        POP R3
        RET

    escreve_azul:
        PUSH R1                     ; guarda os registos alterados por esta rotina
        PUSH R3
        PUSH R5
        PUSH R6
        MOV R1, 27                 ; linha corrente
        MOV R6, 29                 ; coluna corrente
        MOV R5, 31               
            ee_proxima_linha_azul:
            CALL escreve_linha_azul      ; escreve os pixels na linha corrente
            ADD  R1, 1                  ; próxima linha
            CMP  R1, R5                 ; chegou ao fim?
            JLT  ee_proxima_linha_azul
            POP R6
            POP R5
            POP R3
            POP R1
            RET

    escreve_linha_azul:
        PUSH R3
        CALL escreve_pixel_azul      ; escreve o pixel na coluna corrente
        POP  R3
        RET

    escreve_pixel_azul:
        PUSH R3
        MOV R3, AZUL
        MOV  [DEFINE_LINHA], R1     ; seleciona a linha
        MOV  [DEFINE_COLUNA], R6    ; seleciona a coluna
        MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
        POP R3
        RET

    escreve_circulo_verde_esc:
        PUSH R1
        PUSH R2                     
        PUSH R3
        PUSH R4
        PUSH R5
        PUSH R6
        MOV R1, 26                 ; linha corrente
        MOV R6, 32
        MOV  R5, 31
        MOV  R2, 33                 ; coluna corrente
        MOV  R4, 38
            ee_proxima_linha_verde_esc:
            CALL escreve_linha_verde_esc      ; escreve os pixels na linha corrente
            ADD  R1, 1              ; próxima linha
            CMP R2, R6              ; se nao chegou ao tamanho desejado salta para corrigir os valores da coluna
            JNZ ajustes_verde_esc 
            continua_verde_esc:
            CMP  R1, R5             ; chegou ao fim?
            JLT  ee_proxima_linha_verde_esc
            POP R6
            POP R5
            POP R4
            POP R3
            POP R2
            POP R1
            RET

        ajustes_verde_esc:
            SUB R2, 1
            ADD R4, 1
            JMP continua_verde_esc 

    escreve_linha_verde_esc:
        PUSH R2
        PUSH R3
        
            el_proximo_pixel_verde_esc:
            CALL escreve_pixel_verde_esc       ; escreve o pixel na coluna corrente
            ADD  R2, 1               ; próxima coluna
            CMP  R2, R4              ; chegou ao fim?
            JLT  el_proximo_pixel_verde_esc
            POP  R3
            POP  R2
            RET

    escreve_pixel_verde_esc:
        PUSH R3
        MOV R3, VERDE_ESC
        MOV  [DEFINE_LINHA], R1     ; seleciona a linha
        MOV  [DEFINE_COLUNA], R2    ; seleciona a coluna
        MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
        POP R3
        RET

detalhe:
    PUSH R1
    PUSH R2
    PUSH R3
    MOV R1, 27
    MOV R2, 36
    MOV R3, VERDE_CLA
    MOV  [DEFINE_LINHA], R1     ; seleciona a linha
    MOV  [DEFINE_COLUNA], R2    ; seleciona a coluna
    MOV  [DEFINE_PIXEL], R3     ; altera a cor do pixel na linha e coluna já selecionadas
    POP R3
    POP R2
    POP R1
    RET


desenha_boneco:
    PUSH R2
    PUSH R3
    PUSH R8
    PUSH R5
    PUSH R6
    PUSH R7
    MOV R5, [R8]                       ; obtém a largura do boneco
    ADD R8, 2
    MOV R7, [R8]                       ; obtem a altura
    ADD R8, 2                          ; endereço da cor do 1º pixel (2 porque a largura é uma word)
    desenha_pixels_boneco:                        ; desenha os pixels do boneco a partir da tabela
        MOV R6, [R8]                       ; obtém a cor do próximo pixel do boneco
        CALL escreve_pixel_boneco          ; escreve cada pixel do boneco
        ADD  R8, 2                         ; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
        ADD  R3, 1                         ; próxima coluna
        SUB  R5, 1                         ; menos uma coluna para tratar
        JNZ  desenha_pixels_boneco                ; continua até percorrer toda a largura do objeto 
        JMP ajustes_desenha_boneco

        ajustes_desenha_boneco:
        SUB R3, 5
        ADD R2, 1  
        MOV R5, 5
        SUB R7, 1
        JNZ desenha_pixels_boneco

    POP R7
    POP R6
    POP R5
    POP R8
    POP R3
    POP R2
    RET 

apaga_boneco:
    PUSH R2
    PUSH R3
    PUSH R8
    PUSH R5
    PUSH R6
    PUSH R7
    MOV R5, [R8]                       ; obtém a largura do boneco
    ADD R8, 2                          ; endereço da cor do 1º pixel (2 porque a largura é uma word)
    MOV R7, [R8]                       ; obtem a altura
    ADD R8, 2
    apaga_pixels:                          ; desenha os pixels do boneco a partir da tabela
        MOV R6, 0                          ; cor para apagar o próximo pixel do boneco
        CALL escreve_pixel_boneco          ; escreve cada pixel do boneco
        ADD  R8, 2                         ; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
        ADD  R3, 1                         ; próxima coluna
        SUB  R5, 1                         ; menos uma coluna para tratar
        JNZ  apaga_pixels                  ; continua até percorrer toda a largura do objeto
        JMP ajustes_apaga_boneco

        ajustes_apaga_boneco:
        SUB R3, 5
        ADD R2, 1
        MOV R5, 5
        SUB R7, 1
        JNZ apaga_pixels

    POP R7
    POP R6
    POP R5
    POP R8
    POP R3
    POP R2
    RET

escreve_pixel_boneco:
    MOV  [DEFINE_LINHA], R2     ; seleciona a linha
    MOV  [DEFINE_COLUNA], R3        ; seleciona a coluna
    MOV  [DEFINE_PIXEL], R6     ; altera a cor do pixel na linha e coluna já selecionadas
    RET


desenha_sonda:
    PUSH R4
    PUSH R5
    PUSH R6
    MOV R4, AZUL
    MOV R6, 31
    MOV [DEFINE_LINHA], R5
    MOV [DEFINE_COLUNA], R6
    MOV [DEFINE_PIXEL], R4
    POP R6
    POP R5
    POP R4
    RET

apaga_sonda:
    PUSH R4
    PUSH R5
    PUSH R6
    MOV R4, 0
    MOV R6, 31
    MOV [DEFINE_LINHA], R5
    MOV [DEFINE_COLUNA], R6
    MOV [DEFINE_PIXEL], R4
    POP R6
    POP R5
    POP R4
    RET





mostra_display:
    PUSH R1
    MOV R1, DISPLAYS
    MOV R7, 1
    SHL R7, 8
    MOV [R1], R7
    POP R1
    RET

aumenta_display:
    PUSH R1
    MOV R1, DISPLAYS
    ADD R7, 1
    MOV [R1], R7
    POP R1
    RET

diminui_display:
    PUSH R1
    MOV R1, DISPLAYS
    SUB R7, 1
    MOV [R1], R7
    POP R1
    RET