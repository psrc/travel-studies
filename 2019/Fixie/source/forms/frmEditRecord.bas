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
    Width =11820
    DatasheetFontHeight =11
    ItemSuffix =78
    Right =18750
    Bottom =12520
    DatasheetGridlinesColor =15132391
    Filter ="recid = 5038"
    RecSrcDt = Begin
        0xc7915726d451e540
    End
    RecordSource ="qryEditRecord"
    Caption ="qryEditRecord"
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
        Begin CommandButton
            FontSize =11
            FontWeight =400
            FontName ="Calibri"
            ForeThemeColorIndex =0
            ForeTint =75.0
            GridlineThemeColorIndex =1
            GridlineShade =65.0
            UseTheme =1
            Shape =1
            Gradient =12
            BackThemeColorIndex =4
            BackTint =60.0
            BorderLineStyle =0
            BorderColor =16777215
            BorderThemeColorIndex =4
            BorderTint =60.0
            ThemeFontIndex =1
            HoverThemeColorIndex =4
            HoverTint =40.0
            PressedThemeColorIndex =4
            PressedShade =75.0
            HoverForeThemeColorIndex =0
            HoverForeTint =75.0
            PressedForeThemeColorIndex =0
            PressedForeTint =75.0
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
        Begin ToggleButton
            ForeThemeColorIndex =0
            ForeTint =75.0
            GridlineThemeColorIndex =1
            GridlineShade =65.0
            UseTheme =1
            Shape =2
            Bevel =1
            BackColor =-1
            BackThemeColorIndex =4
            BackTint =60.0
            OldBorderStyle =0
            BorderLineStyle =0
            BorderColor =-1
            BorderThemeColorIndex =4
            BorderTint =60.0
            ThemeFontIndex =1
            HoverColor =0
            HoverThemeColorIndex =4
            HoverTint =40.0
            PressedColor =0
            PressedThemeColorIndex =4
            PressedShade =75.0
            HoverForeColor =0
            HoverForeThemeColorIndex =0
            HoverForeTint =75.0
            PressedForeColor =0
            PressedForeThemeColorIndex =1
        End
        Begin FormHeader
            Height =600
            BackColor =15064278
            Name ="FormHeader"
            AlternateBackThemeColorIndex =1
            AlternateBackShade =95.0
            BackThemeColorIndex =2
            BackTint =20.0
            Begin
                Begin Label
                    OverlapFlags =85
                    TextAlign =2
                    Top =60
                    Width =11037
                    Height =480
                    FontSize =20
                    BorderColor =8355711
                    ForeColor =8355711
                    Name ="Label60"
                    Caption ="Trip Record Editor"
                    GridlineColor =10921638
                    LayoutCachedTop =60
                    LayoutCachedWidth =11037
                    LayoutCachedHeight =540
                End
            End
        End
        Begin Section
            Height =9240
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
                    Left =1890
                    Top =360
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="personid"
                    ControlSource ="personid"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =360
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =690
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =360
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="personid_Label"
                            Caption ="personid"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =360
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =690
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =780
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =1
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="hhid"
                    ControlSource ="hhid"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =780
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =1110
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =780
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="hhid_Label"
                            Caption ="hhid"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =780
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =1110
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =1200
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =2
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="pernum"
                    ControlSource ="pernum"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =1200
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =1530
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =1200
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="pernum_Label"
                            Caption ="pernum"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =1200
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =1530
                        End
                    End
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =1620
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =3
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="tripnum"
                    ControlSource ="tripnum"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =1620
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =1950
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =1620
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="tripnum_Label"
                            Caption ="tripnum"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =1620
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =1950
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =2700
                    Width =4770
                    Height =330
                    ColumnWidth =3000
                    TabIndex =4
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="depart_time_timestamp"
                    ControlSource ="depart_time_timestamp"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =2700
                    LayoutCachedWidth =6660
                    LayoutCachedHeight =3030
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =2700
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="depart_time_timestamp_Label"
                            Caption ="depart_time_timestamp"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =2700
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =3030
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =3120
                    Width =4770
                    Height =330
                    ColumnWidth =3000
                    TabIndex =5
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="arrival_time_timestamp"
                    ControlSource ="arrival_time_timestamp"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =3120
                    LayoutCachedWidth =6660
                    LayoutCachedHeight =3450
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =3120
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="arrival_time_timestamp_Label"
                            Caption ="arrival_time_timestamp"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =3120
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =3450
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =780
                    Width =1050
                    Height =330
                    ColumnWidth =1050
                    TabIndex =6
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_1"
                    ControlSource ="mode_1"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =780
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =1110
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =780
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="mode_1_Label"
                            Caption ="mode_1"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =780
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =1110
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =1200
                    Width =1050
                    Height =330
                    ColumnWidth =1050
                    TabIndex =7
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_2"
                    ControlSource ="mode_2"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =1200
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =1530
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =1200
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="mode_2_Label"
                            Caption ="mode_2"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =1200
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =1530
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =1620
                    Width =1050
                    Height =330
                    ColumnWidth =1050
                    TabIndex =8
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_3"
                    ControlSource ="mode_3"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =1620
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =1950
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =1620
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="mode_3_Label"
                            Caption ="mode_3"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =1620
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =1950
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =2040
                    Width =1050
                    Height =330
                    ColumnWidth =1050
                    TabIndex =9
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_4"
                    ControlSource ="mode_4"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =2040
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =2370
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =2040
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="mode_4_Label"
                            Caption ="mode_4"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =2040
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =2370
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =3120
                    Width =1050
                    Height =330
                    ColumnWidth =1050
                    TabIndex =10
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="driver"
                    ControlSource ="driver"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =3120
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =3450
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =3120
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="driver_Label"
                            Caption ="driver"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =3120
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =3450
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =5280
                    Width =4170
                    Height =600
                    ColumnWidth =3000
                    TabIndex =11
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="origin_name"
                    ControlSource ="origin_name"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =5280
                    LayoutCachedWidth =6060
                    LayoutCachedHeight =5880
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =5280
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="origin_name_Label"
                            Caption ="origin_name"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =5280
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =5610
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =6000
                    Width =4170
                    Height =600
                    ColumnWidth =3000
                    TabIndex =12
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="origin_address"
                    ControlSource ="origin_address"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =6000
                    LayoutCachedWidth =6060
                    LayoutCachedHeight =6600
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =6000
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="origin_address_Label"
                            Caption ="origin_address"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =6000
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =6330
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =6720
                    Width =1710
                    Height =330
                    ColumnWidth =3000
                    TabIndex =13
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="origin_lat"
                    ControlSource ="origin_lat"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =6720
                    LayoutCachedWidth =3600
                    LayoutCachedHeight =7050
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =6720
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="origin_lat_Label"
                            Caption ="origin_lat"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =6720
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =7050
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =7140
                    Width =1710
                    Height =330
                    ColumnWidth =3000
                    TabIndex =14
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="origin_lng"
                    ControlSource ="origin_lng"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =7140
                    LayoutCachedWidth =3600
                    LayoutCachedHeight =7470
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =7140
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="origin_lng_Label"
                            Caption ="origin_lng"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =7140
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =7470
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =7770
                    Top =5280
                    Width =3690
                    Height =600
                    ColumnWidth =3000
                    TabIndex =15
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_name"
                    ControlSource ="dest_name"
                    GridlineColor =10921638

                    LayoutCachedLeft =7770
                    LayoutCachedTop =5280
                    LayoutCachedWidth =11460
                    LayoutCachedHeight =5880
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =6240
                            Top =5280
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_name_Label"
                            Caption ="dest_name"
                            GridlineColor =10921638
                            LayoutCachedLeft =6240
                            LayoutCachedTop =5280
                            LayoutCachedWidth =7680
                            LayoutCachedHeight =5610
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =7770
                    Top =6000
                    Width =3690
                    Height =600
                    ColumnWidth =3000
                    TabIndex =16
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_address"
                    ControlSource ="dest_address"
                    GridlineColor =10921638

                    LayoutCachedLeft =7770
                    LayoutCachedTop =6000
                    LayoutCachedWidth =11460
                    LayoutCachedHeight =6600
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =6240
                            Top =6000
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_address_Label"
                            Caption ="dest_address"
                            GridlineColor =10921638
                            LayoutCachedLeft =6240
                            LayoutCachedTop =6000
                            LayoutCachedWidth =7680
                            LayoutCachedHeight =6330
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =7770
                    Top =6720
                    Width =1890
                    Height =330
                    ColumnWidth =3000
                    TabIndex =17
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_lat"
                    ControlSource ="dest_lat"
                    GridlineColor =10921638

                    LayoutCachedLeft =7770
                    LayoutCachedTop =6720
                    LayoutCachedWidth =9660
                    LayoutCachedHeight =7050
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =6240
                            Top =6720
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_lat_Label"
                            Caption ="dest_lat"
                            GridlineColor =10921638
                            LayoutCachedLeft =6240
                            LayoutCachedTop =6720
                            LayoutCachedWidth =7680
                            LayoutCachedHeight =7050
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =7770
                    Top =7140
                    Width =1890
                    Height =330
                    ColumnWidth =3000
                    TabIndex =18
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_lng"
                    ControlSource ="dest_lng"
                    GridlineColor =10921638

                    LayoutCachedLeft =7770
                    LayoutCachedTop =7140
                    LayoutCachedWidth =9660
                    LayoutCachedHeight =7470
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =6240
                            Top =7140
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_lng_Label"
                            Caption ="dest_lng"
                            GridlineColor =10921638
                            LayoutCachedLeft =6240
                            LayoutCachedTop =7140
                            LayoutCachedWidth =7680
                            LayoutCachedHeight =7470
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =5160
                    Top =3540
                    Width =1500
                    Height =330
                    ColumnWidth =3000
                    TabIndex =19
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="trip_path_distance"
                    ControlSource ="trip_path_distance"
                    GridlineColor =10921638

                    LayoutCachedLeft =5160
                    LayoutCachedTop =3540
                    LayoutCachedWidth =6660
                    LayoutCachedHeight =3870
                    Begin
                        Begin Label
                            OverlapFlags =85
                            TextAlign =3
                            Left =1860
                            Top =3540
                            Width =3180
                            Height =300
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="trip_path_distance_Label"
                            Caption ="trip_path_distance (calculated)"
                            GridlineColor =10921638
                            LayoutCachedLeft =1860
                            LayoutCachedTop =3540
                            LayoutCachedWidth =5040
                            LayoutCachedHeight =3840
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =5130
                    Top =3960
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =20
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="google_duration"
                    ControlSource ="google_duration"
                    GridlineColor =10921638

                    LayoutCachedLeft =5130
                    LayoutCachedTop =3960
                    LayoutCachedWidth =6660
                    LayoutCachedHeight =4290
                    Begin
                        Begin Label
                            OverlapFlags =85
                            TextAlign =3
                            Left =1860
                            Top =3960
                            Width =3180
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="google_duration_Label"
                            Caption ="google_duration (calculated)"
                            GridlineColor =10921638
                            LayoutCachedLeft =1860
                            LayoutCachedTop =3960
                            LayoutCachedWidth =5040
                            LayoutCachedHeight =4290
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =5130
                    Top =4380
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =21
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="reported_duration"
                    ControlSource ="reported_duration"
                    GridlineColor =10921638

                    LayoutCachedLeft =5130
                    LayoutCachedTop =4380
                    LayoutCachedWidth =6660
                    LayoutCachedHeight =4710
                    Begin
                        Begin Label
                            OverlapFlags =85
                            TextAlign =3
                            Left =1860
                            Top =4380
                            Width =3180
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="reported_duration_Label"
                            Caption ="reported_duration (calculated)"
                            GridlineColor =10921638
                            LayoutCachedLeft =1860
                            LayoutCachedTop =4380
                            LayoutCachedWidth =5040
                            LayoutCachedHeight =4710
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =3540
                    Width =1050
                    Height =330
                    ColumnWidth =1530
                    TabIndex =22
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="travelers_hh"
                    ControlSource ="travelers_hh"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =3540
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =3870
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =3540
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="travelers_hh_Label"
                            Caption ="travelers_hh"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =3540
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =3870
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =3960
                    Width =1050
                    Height =330
                    ColumnWidth =1530
                    TabIndex =23
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="travelers_nonhh"
                    ControlSource ="travelers_nonhh"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =3960
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =4290
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =3960
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="travelers_nonhh_Label"
                            Caption ="travelers_nonhh"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =3960
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =4290
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =4380
                    Width =1050
                    Height =330
                    ColumnWidth =1530
                    TabIndex =24
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="travelers_total"
                    ControlSource ="travelers_total"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =4380
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =4710
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =4380
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="travelers_total_Label"
                            Caption ="travelers_total"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =4380
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =4710
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =4860
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =25
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="origin_purpose"
                    ControlSource ="origin_purpose"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =4860
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =5190
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =4860
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="origin_purpose_Label"
                            Caption ="origin_purpose"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =4860
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =5190
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =7560
                    Width =3690
                    Height =360
                    ColumnWidth =3000
                    TabIndex =26
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="o_purpose_other"
                    ControlSource ="o_purpose_other"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =7560
                    LayoutCachedWidth =5580
                    LayoutCachedHeight =7920
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =7560
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="o_purpose_other_Label"
                            Caption ="o_purpose_other"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =7560
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =7890
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =7770
                    Top =4860
                    Width =1530
                    Height =330
                    ColumnWidth =1530
                    TabIndex =27
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="dest_purpose"
                    ControlSource ="dest_purpose"
                    GridlineColor =10921638

                    LayoutCachedLeft =7770
                    LayoutCachedTop =4860
                    LayoutCachedWidth =9300
                    LayoutCachedHeight =5190
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =6240
                            Top =4860
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="dest_purpose_Label"
                            Caption ="dest_purpose"
                            GridlineColor =10921638
                            LayoutCachedLeft =6240
                            LayoutCachedTop =4860
                            LayoutCachedWidth =7680
                            LayoutCachedHeight =5190
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =360
                    Width =1050
                    Height =330
                    TabIndex =28
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_acc"
                    ControlSource ="mode_acc"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =360
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =690
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =360
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Label64"
                            Caption ="mode_acc"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =360
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =690
                        End
                    End
                End
                Begin TextBox
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =8910
                    Top =2460
                    Width =1050
                    Height =330
                    TabIndex =29
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="mode_egr"
                    ControlSource ="mode_egr"
                    GridlineColor =10921638

                    LayoutCachedLeft =8910
                    LayoutCachedTop =2460
                    LayoutCachedWidth =9960
                    LayoutCachedHeight =2790
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =7380
                            Top =2460
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Label66"
                            Caption ="mode_egr"
                            GridlineColor =10921638
                            LayoutCachedLeft =7380
                            LayoutCachedTop =2460
                            LayoutCachedWidth =8820
                            LayoutCachedHeight =2790
                        End
                    End
                End
                Begin ToggleButton
                    OverlapFlags =85
                    TextFontCharSet =177
                    TextFontFamily =0
                    Left =10260
                    Top =8400
                    Width =1200
                    Height =360
                    TabIndex =30
                    ForeColor =4210752
                    Name ="DeleteTripButton"
                    Caption ="Delete Trip"
                    FontName ="Calibri"
                    OnClick ="[Event Procedure]"
                    GridlineColor =10921638

                    LayoutCachedLeft =10260
                    LayoutCachedTop =8400
                    LayoutCachedWidth =11460
                    LayoutCachedHeight =8760
                    BackColor =7961551
                    BackThemeColorIndex =-1
                    BackTint =100.0
                    BorderColor =14461583
                    HoverColor =15189940
                    PressedColor =9917743
                    HoverForeColor =4210752
                    PressedForeColor =16777215
                    WebImagePaddingLeft =3
                    WebImagePaddingTop =3
                    WebImagePaddingRight =2
                    WebImagePaddingBottom =3
                End
                Begin TextBox
                    Locked = NotDefault
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =1890
                    Top =2040
                    Width =1530
                    Height =330
                    TabIndex =31
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="recid"
                    ControlSource ="recid"
                    GridlineColor =10921638

                    LayoutCachedLeft =1890
                    LayoutCachedTop =2040
                    LayoutCachedWidth =3420
                    LayoutCachedHeight =2370
                    Begin
                        Begin Label
                            OverlapFlags =85
                            Left =360
                            Top =2040
                            Width =1440
                            Height =330
                            BorderColor =8355711
                            ForeColor =8355711
                            Name ="Label69"
                            Caption ="recid"
                            GridlineColor =10921638
                            LayoutCachedLeft =360
                            LayoutCachedTop =2040
                            LayoutCachedWidth =1800
                            LayoutCachedHeight =2370
                        End
                    End
                End
                Begin TextBox
                    EnterKeyBehavior = NotDefault
                    ScrollBars =2
                    OverlapFlags =85
                    IMESentenceMode =3
                    Left =5310
                    Top =8400
                    Width =3690
                    Height =360
                    TabIndex =32
                    BorderColor =10921638
                    ForeColor =4210752
                    Name ="psrc_comment"
                    ControlSource ="psrc_comment"
                    GridlineColor =10921638

                    LayoutCachedLeft =5310
                    LayoutCachedTop =8400
                    LayoutCachedWidth =9000
                    LayoutCachedHeight =8760
                End
                Begin ToggleButton
                    OverlapFlags =85
                    TextFontCharSet =177
                    TextFontFamily =0
                    Left =420
                    Top =8400
                    Width =1680
                    Height =360
                    TabIndex =33
                    ForeColor =16777215
                    Name ="DismissFlagButton"
                    Caption ="Dismiss Flag"
                    FontName ="Calibri"
                    OnClick ="[Event Procedure]"
                    GridlineColor =10921638

                    LayoutCachedLeft =420
                    LayoutCachedTop =8400
                    LayoutCachedWidth =2100
                    LayoutCachedHeight =8760
                    ForeThemeColorIndex =1
                    ForeTint =100.0
                    BackColor =3506772
                    BackThemeColorIndex =9
                    BackTint =100.0
                    BackShade =75.0
                    BorderColor =14461583
                    HoverColor =15189940
                    PressedColor =9917743
                    HoverForeColor =4210752
                    PressedForeColor =16777215
                    WebImagePaddingLeft =3
                    WebImagePaddingTop =3
                    WebImagePaddingRight =3
                    WebImagePaddingBottom =2
                End
                Begin ToggleButton
                    OverlapFlags =85
                    TextFontCharSet =177
                    TextFontFamily =0
                    Left =2700
                    Top =8400
                    Width =2520
                    Height =360
                    TabIndex =34
                    ForeColor =4210752
                    Name ="ElevateButton"
                    Caption ="Elevate (describe Issue:)"
                    FontName ="Calibri"
                    OnClick ="[Event Procedure]"
                    GridlineColor =10921638

                    LayoutCachedLeft =2700
                    LayoutCachedTop =8400
                    LayoutCachedWidth =5220
                    LayoutCachedHeight =8760
                    BackColor =49407
                    BackThemeColorIndex =7
                    BackTint =100.0
                    BorderColor =14461583
                    HoverColor =15189940
                    PressedColor =9917743
                    HoverForeColor =4210752
                    PressedForeColor =16777215
                    WebImagePaddingLeft =3
                    WebImagePaddingTop =3
                    WebImagePaddingRight =2
                    WebImagePaddingBottom =2
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

Private Sub DeleteTripButton_Click()
    lngParam = Forms![frmEditRecord]![recid]
    Call ExecutePassThrough(lngParam)

End Sub

Private Sub DismissFlagButton_Click()
    On Error GoTo HandleError
    Me![psrc_resolved].Value = 1
    Me.Dirty = False
    DoCmd.RunCommand acCmdSaveRecord
    DoCmd.Close ObjectType:=acForm, ObjectName:=Me.Name, Save:=acSavePrompt
HandleExit:
    Exit Sub
HandleError:
    MsgBox Err.Description
    Resume HandleExit
    
End Sub

Private Sub ElevateButton_Click()
  If IsNull(Me.psrc_comment) Then
      MsgBox "Please describe problem.", vbOKOnly
  Else
      DoCmd.RunCommand acCmdSaveRecord
      DoCmd.Close ObjectType:=acForm, ObjectName:=Me.Name, Save:=acSavePrompt
  End If
    
End Sub
