Version =21
VersionRequired =20
Begin Form
    AutoCenter = NotDefault
    DividingLines = NotDefault
    AllowDesignChanges = NotDefault
    DefaultView =0
    ViewsAllowed =1
    PictureAlignment =2
    DatasheetGridlinesBehavior =3
    GridX =24
    GridY =24
    Width =22800
    DatasheetFontHeight =11
    ItemSuffix =20
    Right =23475
    Bottom =13680
    DatasheetGridlinesColor =15132391
    RecSrcDt = Begin
        0xf77ad079d151e540
    End
    RecordSource ="qryPerson"
    Caption ="frmPerson"
    OnCurrent ="[Event Procedure]"
    OnClose ="[Event Procedure]"
    DatasheetFontName ="Calibri"
    PrtMip = Begin
        0x6801000068010000680100006801000000000000201c0000e010000001000000 ,
        0x010000006801000000000000a10700000100000001000000
    End
    AllowDatasheetView =0
    FilterOnLoad =0
    ShowPageMargins =0
    DisplayOnSharePointSite =1
    DatasheetAlternateBackColor =15921906
    DatasheetGridlinesColor12 =0
    FitToScreen =1
    DatasheetBackThemeColorIndex =1
    BorderThemeColorIndex =3
    ThemeFontIndex =1
    ForeThemeColorIndex =0
    AlternateBackThemeColorIndex =1
    AlternateBackShade =95.0
    Begin
        Begin Label
            BackStyle =0
            FontSize =11
            FontName ="Calibri"
            ThemeFontIndex =1
            BackThemeColorIndex =1
            BorderThemeColorIndex =0
            BorderTint =50.0
            ForeThemeColorIndex =0
            ForeTint =50.0
            GridlineThemeColorIndex =1
            GridlineShade =65.0
        End
        Begin TextBox
            AddColon = NotDefault
            FELineBreak = NotDefault
            BorderLineStyle =0
            LabelX =-1800
            FontSize =11
            FontName ="Calibri"
            AsianLineBreak =1
            BackThemeColorIndex =1
            BorderThemeColorIndex =1
            BorderShade =65.0
            ThemeFontIndex =1
            ForeThemeColorIndex =0
            ForeTint =75.0
            GridlineThemeColorIndex =1
            GridlineShade =65.0
        End
        Begin ComboBox
            AddColon = NotDefault
            BorderLineStyle =0
            LabelX =-1800
            FontSize =11
            FontName ="Calibri"
            AllowValueListEdits =1
            InheritValueList =1
            ThemeFontIndex =1
            BackThemeColorIndex =1
            BorderThemeColorIndex =1
            BorderShade =65.0
            ForeThemeColorIndex =2
            ForeShade =50.0
            GridlineThemeColorIndex =1
            GridlineShade =65.0
        End
        Begin Subform
            BorderLineStyle =0
            BorderThemeColorIndex =1
            GridlineThemeColorIndex =1
            GridlineShade =65.0
            BorderShade =65.0
            ShowPageHeaderAndPageFooter =1
        End
        Begin FormHeader
            Height =1080
            BackColor =15064278
            Name ="FormHeader"
            AutoHeight =1
            AlternateBackThemeColorIndex =1
            AlternateBackShade =95.0
            BackThemeColorIndex =2
            BackTint =20.0
            Begin
                Begin Label
                    OverlapFlags =85
                    TextAlign =3
                    Left =360
                    Top =720
                    Width =2040
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="personid_Label"
                    Caption ="personid"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =360
                    LayoutCachedTop =720
                    LayoutCachedWidth =2400
                    LayoutCachedHeight =1035
                End
                Begin Label
                    OverlapFlags =85
                    TextAlign =3
                    Left =2580
                    Top =720
                    Width =1680
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="hhid_Label"
                    Caption ="hhid"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =2580
                    LayoutCachedTop =720
                    LayoutCachedWidth =4260
                    LayoutCachedHeight =1035
                End
                Begin Label
                    OverlapFlags =85
                    TextAlign =3
                    Left =4380
                    Top =720
                    Width =1080
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="pernum_Label"
                    Caption ="pernum"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =4380
                    LayoutCachedTop =720
                    LayoutCachedWidth =5460
                    LayoutCachedHeight =1035
                End
                Begin Label
                    OverlapFlags =85
                    TextAlign =1
                    Left =5520
                    Top =720
                    Width =2580
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="Age_Label"
                    Caption ="Age"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =5520
                    LayoutCachedTop =720
                    LayoutCachedWidth =8100
                    LayoutCachedHeight =1035
                End
                Begin Label
                    OverlapFlags =85
                    TextAlign =1
                    Left =8160
                    Top =720
                    Width =720
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="Works_Label"
                    Caption ="Works"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =8160
                    LayoutCachedTop =720
                    LayoutCachedWidth =8880
                    LayoutCachedHeight =1035
                End
                Begin Label
                    OverlapFlags =85
                    TextAlign =1
                    Left =8895
                    Top =720
                    Width =780
                    Height =315
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="Studies_Label"
                    Caption ="Studies"
                    Tag ="DetachedLabel"
                    GridlineStyleBottom =1
                    GridlineColor =10921638
                    LayoutCachedLeft =8895
                    LayoutCachedTop =720
                    LayoutCachedWidth =9675
                    LayoutCachedHeight =1035
                End
            End
        End
        Begin Section
            CanGrow = NotDefault
            Height =11340
            Name ="Detail"
            AlternateBackColor =15921906
            AlternateBackThemeColorIndex =1
            AlternateBackShade =95.0
            BackThemeColorIndex =1
            Begin
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =5520
                    Top =60
                    Width =2580
                    Height =330
                    ColumnWidth =3000
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="Age"
                    ControlSource ="Age"
                    GridlineColor =10921638

                    LayoutCachedLeft =5520
                    LayoutCachedTop =60
                    LayoutCachedWidth =8100
                    LayoutCachedHeight =390
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8115
                    Top =60
                    Width =720
                    Height =330
                    ColumnWidth =3000
                    TabIndex =1
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="Works"
                    ControlSource ="Works"
                    GridlineColor =10921638

                    LayoutCachedLeft =8115
                    LayoutCachedTop =60
                    LayoutCachedWidth =8835
                    LayoutCachedHeight =390
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8895
                    Top =60
                    Width =780
                    Height =330
                    ColumnWidth =3000
                    TabIndex =2
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="Studies"
                    ControlSource ="Studies"
                    GridlineColor =10921638

                    LayoutCachedLeft =8895
                    LayoutCachedTop =60
                    LayoutCachedWidth =9675
                    LayoutCachedHeight =390
                End
                Begin Subform
                    OverlapFlags =215
                    Left =300
                    Top =1080
                    Width =22260
                    Height =8220
                    TabIndex =3
                    BorderColor =10921638
                    Name ="qryErrorViewer"
                    SourceObject ="Form.sfrmPerson_errortrip"
                    LinkChildFields ="personid"
                    LinkMasterFields ="personid"
                    GridlineColor =10921638

                    LayoutCachedLeft =300
                    LayoutCachedTop =1080
                    LayoutCachedWidth =22560
                    LayoutCachedHeight =9300
                    Begin
                        Begin Label
                            OverlapFlags =93
                            Left =1380
                            Top =840
                            Width =1500
                            Height =315
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Label14"
                            Caption ="qryErrorViewer"
                            GridlineColor =10921638
                            LayoutCachedLeft =1380
                            LayoutCachedTop =840
                            LayoutCachedWidth =2880
                            LayoutCachedHeight =1155
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2580
                    Top =60
                    Width =1680
                    Height =315
                    TabIndex =4
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="hhid"
                    ControlSource ="hhid"
                    GridlineColor =10921638

                    LayoutCachedLeft =2580
                    LayoutCachedTop =60
                    LayoutCachedWidth =4260
                    LayoutCachedHeight =375
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =4380
                    Top =60
                    Width =1080
                    Height =315
                    TabIndex =5
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="pernum"
                    ControlSource ="pernum"
                    GridlineColor =10921638

                    LayoutCachedLeft =4380
                    LayoutCachedTop =60
                    LayoutCachedWidth =5460
                    LayoutCachedHeight =375
                End
                Begin ComboBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    ListWidth =1440
                    Left =420
                    Top =60
                    Width =2040
                    Height =315
                    TabIndex =6
                    BorderColor =10921638
                    ForeColor =3484194
                    ColumnInfo ="\"\";\"\";\"4\";\"4\""
                    Name ="cboFindPerson"
                    RowSourceType ="Table/Query"
                    RowSource ="SELECT [qryPerson].[personid] FROM qryPerson; "
                    ColumnWidths ="1440"
                    GridlineColor =10921638
                    AfterUpdateEmMacro = Begin
                        Version =196611
                        ColumnsShown =12
                        Begin
                            Action ="SearchForRecord"
                            Argument ="-1"
                            Argument =""
                            Argument ="2"
                            Argument ="=\"[personid] = \"& Str(Nz([Screen].[ActiveControl], 0))"
                        End
                        Begin
                            Comment ="_AXL:<?xml version=\"1.0\" encoding=\"UTF-16\" standalone=\"no\"?>\015\012<UserI"
                                "nterfaceMacro For=\"cboFindPerson\" xmlns=\"http://schemas.microsoft.com/office/"
                                "accessservices/2009/11/application\"><Statements><Action Name=\"SearchForRecord\""
                                "><Argument Name=\"WhereConditio"
                        End
                        Begin
                            Comment ="_AXL:n\">=\"[personid] = \"&amp; Str(Nz([Screen].[ActiveControl], 0))</Argument>"
                                "</Action></Statements></UserInterfaceMacro>"
                        End
                    End

                    LayoutCachedLeft =420
                    LayoutCachedTop =60
                    LayoutCachedWidth =2460
                    LayoutCachedHeight =375
                End
            End
        End
        Begin FormFooter
            Height =0
            Name ="FormFooter"
            AutoHeight =1
            AlternateBackThemeColorIndex =1
            AlternateBackShade =95.0
            BackThemeColorIndex =1
        End
    End
End
CodeBehindForm
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Compare Database
Option Explicit



Private Sub Form_Close()
    DoCmd.SetWarnings False
    DoCmd.OpenQuery "qsptGenerateFlags"
    DoCmd.SetWarnings True
End Sub

Private Sub Form_Current()
    Me.cboFindPerson = Me.personid
End Sub
