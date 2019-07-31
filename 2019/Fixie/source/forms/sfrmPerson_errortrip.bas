Version =21
VersionRequired =20
Begin Form
    AutoCenter = NotDefault
    DividingLines = NotDefault
    AllowDesignChanges = NotDefault
    DefaultView =2
    PictureAlignment =2
    DatasheetGridlinesBehavior =3
    GridX =24
    GridY =24
    Width =10230
    DatasheetFontHeight =11
    ItemSuffix =29
    Left =585
    Top =2160
    Right =22830
    Bottom =10110
    DatasheetGridlinesColor =15132391
    RecSrcDt = Begin
        0x5019ff8ed151e540
    End
    RecordSource ="qryErrorViewer"
    Caption ="qryErrorViewer"
    AfterUpdate ="[Event Procedure]"
    DatasheetFontName ="Calibri"
    PrtMip = Begin
        0x6801000068010000680100006801000000000000201c0000e010000001000000 ,
        0x010000006801000000000000a10700000100000001000000
    End
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
        Begin Section
            Height =8430
            Name ="Detail"
            AutoHeight =1
            AlternateBackColor =15921906
            AlternateBackThemeColorIndex =1
            AlternateBackShade =95.0
            BackThemeColorIndex =1
            Begin
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =780
                    Width =1530
                    Height =330
                    ColumnWidth =960
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="tripnum"
                    ControlSource ="tripnum"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =780
                    LayoutCachedWidth =4440
                    LayoutCachedHeight =1110
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =780
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="tripnum_Label"
                            Caption ="tripnum"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =780
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =1110
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =1200
                    Width =7260
                    Height =600
                    ColumnWidth =2820
                    TabIndex =1
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="modes_desc"
                    ControlSource ="modes_desc"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =1200
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =1800
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =1200
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="modes_desc_Label"
                            Caption ="modes_desc"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =1200
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =1530
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =1920
                    Width =5460
                    Height =330
                    ColumnWidth =1275
                    TabIndex =2
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="daynum"
                    ControlSource ="daynum"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =1920
                    LayoutCachedWidth =8370
                    LayoutCachedHeight =2250
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =1920
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="daynum_Label"
                            Caption ="daynum"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =1920
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =2250
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =2340
                    Width =7260
                    Height =1140
                    ColumnWidth =1425
                    TabIndex =3
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="depart_dhm"
                    ControlSource ="depart_dhm"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =2340
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =3480
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =2340
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="depart_dhm_Label"
                            Caption ="depart_dhm"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =2340
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =2670
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =3600
                    Width =3660
                    Height =330
                    ColumnWidth =975
                    TabIndex =4
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mph"
                    ControlSource ="mph"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =3600
                    LayoutCachedWidth =6570
                    LayoutCachedHeight =3930
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =3600
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="mph_Label"
                            Caption ="mph"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =3600
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =3930
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =4020
                    Width =3660
                    Height =330
                    ColumnWidth =1185
                    TabIndex =5
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="miles"
                    ControlSource ="miles"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =4020
                    LayoutCachedWidth =6570
                    LayoutCachedHeight =4350
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =4020
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="miles_Label"
                            Caption ="miles"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =4020
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =4350
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =4440
                    Width =7260
                    Height =1140
                    ColumnWidth =1410
                    TabIndex =6
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="arrive_dhm"
                    ControlSource ="arrive_dhm"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =4440
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =5580
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =4440
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="arrive_dhm_Label"
                            Caption ="arrive_dhm"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =4440
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =4770
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =5760
                    Width =7260
                    Height =600
                    ColumnWidth =2820
                    TabIndex =7
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="Error"
                    ControlSource ="Error"
                    OnClick ="[Event Procedure]"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =5760
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =6360
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =5760
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Error_Label"
                            Caption ="Error"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =5760
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =6090
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =6420
                    Width =7260
                    Height =330
                    ColumnWidth =1380
                    TabIndex =8
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="cotravelers"
                    ControlSource ="cotravelers"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =6420
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =6750
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =6420
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="cotravelers_Label"
                            Caption ="cotravelers"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =6420
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =6750
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =6840
                    Width =7260
                    Height =600
                    ColumnWidth =1850
                    TabIndex =9
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_name"
                    ControlSource ="dest_name"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =6840
                    LayoutCachedWidth =10170
                    LayoutCachedHeight =7440
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =6840
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_name_Label"
                            Caption ="dest_name"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =6840
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =7170
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =7560
                    Width =3660
                    Height =330
                    ColumnWidth =2265
                    TabIndex =10
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_purpose"
                    ControlSource ="dest_purpose"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =7560
                    LayoutCachedWidth =6570
                    LayoutCachedHeight =7890
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =7560
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_purpose_Label"
                            Caption ="dest_purpose"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =7560
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =7890
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =7980
                    Width =4140
                    Height =330
                    ColumnWidth =2115
                    TabIndex =11
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="duration_at_dest"
                    ControlSource ="duration_at_dest"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =7980
                    LayoutCachedWidth =7050
                    LayoutCachedHeight =8310
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =7980
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="duration_at_dest_Label"
                            Caption ="duration_at_dest"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =7980
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =8310
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =2910
                    Top =360
                    Width =1530
                    Height =330
                    TabIndex =12
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="recid"
                    ControlSource ="recid"
                    GridlineColor =10921638

                    LayoutCachedLeft =2910
                    LayoutCachedTop =360
                    LayoutCachedWidth =4440
                    LayoutCachedHeight =690
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =360
                            Width =2460
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Label28"
                            Caption ="recid"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =360
                            LayoutCachedWidth =2820
                            LayoutCachedHeight =690
                        End
                    End
                End
            End
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

Private Sub Error_Click()
DoCmd.OpenForm "frmEditRecord", , , "recid = " & Me.recid
End Sub

Private Sub Form_AfterUpdate()
Dim sql

sql = "SELECT personid, tripnum, modes_desc, daynum, depart_dhm, mph, miles, arrive_dhm, Error, cotravelers, dest_name, dest_purpose, duration_at_dest" _
    & "FROM Mike_data2frontend" _
    & "WHERE personid = " & Me.personid _
    & "ORDER BY personid, tripnum;"

Me.sfrmPerson_errortrip.Form.RecordSource = sql
Me.sfrmPerson_errortrip.Form.Requery

End Sub
