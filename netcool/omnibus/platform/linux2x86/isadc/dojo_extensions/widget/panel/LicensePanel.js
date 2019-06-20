/*
  (C) COPYRIGHT International Business Machines Corp., 2012. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.LicensePanel");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.form.Select");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.LicensePanel", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/LicensePanel.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
		
	//License was accepted?
	licenseAccepted:false,
	
	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:false,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("LicensePanel constructor is called: ");
	
		this.localeSupported=["en","cs","de","el","es","fr","in","it","ja","ko","lt","pl","pt","ru","sl","tr","zh","zh-tw"];
		
		this.localizedStrings={ //title_text
				sofwareLicenseAgreement:{
			        'en':'Software License Agreement',
			        'cs':'Software License Agreement',
			        'fr':'Contrat de licence',
			        'de':'Softwarelizenzvereinbarung',
			        'el':'&#x03a3;&#x03cd;&#x03bc;&#x03b2;&#x03b1;&#x03c3;&#x03b7; &#x0386;&#x03b4;&#x03b5;&#x03b9;&#x03b1;&#x03c2; &#x03a7;&#x03c1;&#x03ae;&#x03c3;&#x03b7;&#x03c2; &#x039b;&#x03bf;&#x03b3;&#x03b9;&#x03c3;&#x03bc;&#x03b9;&#x03ba;&#x03bf;&#x03cd;',
			        'es':'Acuerdo de licencia de software',
			        'in':'Perjanjian Lisensi Perangkat Lunak',
			        'it':'Accordo di Licenza Software',
			        'ja':'&#x30bd;&#x30d5;&#x30c8;&#x30a6;&#x30a7;&#x30a2;&#x4f7f;&#x7528;&#x8a31;&#x8afe;&#x5951;&#x7d04;',
			        'ko':'&#xc18c;&#xd504;&#xd2b8;&#xc6e8;&#xc5b4; &#xb77c;&#xc774;&#xc13c;&#xc2a4; &#xacc4;&#xc57d;',
			        'lt':'Programin&#x0117;s &#x012f;rangos licencijos sutartis',
			        'pl':'Umowa Licencyjna na Oprogramowanie',
			        'pt':'Contrato de Licen&#x00e7;a/Acordo de Licenciamento de Software',
			        'ru':'&#x041b;&#x0438;&#x0446;&#x0435;&#x043d;&#x0437;&#x0438;&#x043e;&#x043d;&#x043d;&#x043e;&#x0435; &#x0421;&#x043e;&#x0433;&#x043b;&#x0430;&#x0448;&#x0435;&#x043d;&#x0438;&#x0435; &#x043e; &#x041f;&#x0440;&#x043e;&#x0433;&#x0440;&#x0430;&#x043c;&#x043c;&#x043d;&#x043e;&#x043c; &#x041e;&#x0431;&#x0435;&#x0441;&#x043f;&#x0435;&#x0447;&#x0435;&#x043d;&#x0438;&#x0438;',
			        'sl':'Licen&#x010d;na pogodba za programsko opremo',
			        'zh':'&#x8f6f;&#x4ef6;&#x8bb8;&#x53ef;&#x534f;&#x8bae;',
			        'zh-tw':'&#x8edf;&#x9ad4;&#x6388;&#x6b0a;&#x5408;&#x7d04;',
			        'tr':'Yaz&#x0131;l&#x0131;m Lisans S&#x00f6;zle&#x015f;mesi'
			    },
			    agreeDeclineMessage:{//submit_text
			    	'en':"By clicking on <B>I agree</B>, you agree that (1) you have had the opportunity to review the terms of both the IBM and non-IBM licenses presented below and (2) such terms govern this transaction. If you do not agree, click <B>I do not agree</B>.",
			    	'cs':'Klepnut&#x00ed;m na <B>Souhlas&#x00ed;m</B> vyjad&#x0159;ujete sv&#x016f;j souhlas s t&#x00ed;m, &#x017e;e (1) jste m&#x011b;li mo&#x017e;nost p&#x0159;e&#x010d;&#x00ed;st si n&#x00ed;&#x017e;e uveden&#x00e9; smluvn&#x00ed; podm&#x00ed;nky a (2) &#x017e;e tato transakce se t&#x011b;mito podm&#x00ed;nkami &#x0159;&#x00ed;d&#x00ed;.  Jestli&#x017e;e nesouhlas&#x00ed;te, klepn&#x011b;te na <B>Nesouhlas&#x00ed;m</B>.',
			    	'fr':"En cliquant sur le bouton <B>J'accepte</B>, vous reconnaissez (1) que vous avez eu l'opportunit&#x00e9; de consulter les dispositions du Contrat pr&#x00e9;sent&#x00e9; ci-apr&#x00e8;s et (2) que ces dispositions r&#x00e9;gissent la pr&#x00e9;sente transaction. Si vous refusez ces dispositions, cliquez sur <B>Je refuse</B>.",
			    	'de':"Durch Klicken auf <B>Anerkennen</B> best&#x00e4;tigen Sie, dass Sie (1) Gelegenheit hatten, die Bedingungen der nachfolgenden Vereinbarung zu pr&#x00fc;fen, und dass (2) diese Bedingungen f&#x00fc;r diese Transaktion ma&#x00df;gebend sind. Wenn Sie den Bedingungen nicht zustimmen, klicken Sie auf <B>Ablehnen</B>.",
			    	'es':"Al pulsar <B>Acepto</B>, acepta que (1) ha tenido la oportunidad de revisar los t&#x00e9;rminos del acuerdo que se muestra a continuaci&#x00f3;n y que (2) dichos t&#x00e9;rminos rigen esta transacci&#x00f3;n. Si no lo acepta, pulse <B>No acepto</B>.",
			    	'el':'&#x03a0;&#x03b1;&#x03c4;&#x03ce;&#x03bd;&#x03c4;&#x03b1;&#x03c2; &#x03c4;&#x03bf; &#x03ba;&#x03bf;&#x03c5;&#x03bc;&#x03c0;&#x03af; <B>&#x03a3;&#x03c5;&#x03bc;&#x03c6;&#x03c9;&#x03bd;&#x03ce;</B>, &#x03b1;&#x03c0;&#x03bf;&#x03b4;&#x03ad;&#x03c7;&#x03b5;&#x03c3;&#x03c4;&#x03b5; (1) &#x03cc;&#x03c4;&#x03b9; &#x03c3;&#x03b1;&#x03c2; &#x03b4;&#x03cc;&#x03b8;&#x03b7;&#x03ba;&#x03b5; &#x03b7; &#x03b5;&#x03c5;&#x03ba;&#x03b1;&#x03b9;&#x03c1;&#x03af;&#x03b1; &#x03bd;&#x03b1; &#x03b4;&#x03b9;&#x03b1;&#x03b2;&#x03ac;&#x03c3;&#x03b5;&#x03c4;&#x03b5; &#x03c4;&#x03bf;&#x03c5;&#x03c2; &#x03cc;&#x03c1;&#x03bf;&#x03c5;&#x03c2; &#x03c4;&#x03b7;&#x03c2; &#x03c3;&#x03cd;&#x03bc;&#x03b2;&#x03b1;&#x03c3;&#x03b7;&#x03c2; &#x03c0;&#x03bf;&#x03c5; &#x03c0;&#x03b1;&#x03c1;&#x03bf;&#x03c5;&#x03c3;&#x03b9;&#x03ac;&#x03b6;&#x03b5;&#x03c4;&#x03b1;&#x03b9; &#x03c0;&#x03b1;&#x03c1;&#x03b1;&#x03ba;&#x03ac;&#x03c4;&#x03c9; &#x03ba;&#x03b1;&#x03b9; (2) &#x03cc;&#x03c4;&#x03b9; &#x03bf;&#x03b9; &#x03b5;&#x03bd; &#x03bb;&#x03cc;&#x03b3;&#x03c9; &#x03cc;&#x03c1;&#x03bf;&#x03b9; &#x03b4;&#x03b9;&#x03ad;&#x03c0;&#x03bf;&#x03c5;&#x03bd; &#x03c4;&#x03b7;&#x03bd; &#x03c0;&#x03b1;&#x03c1;&#x03bf;&#x03cd;&#x03c3;&#x03b1; &#x03c3;&#x03c5;&#x03bd;&#x03b1;&#x03bb;&#x03bb;&#x03b1;&#x03b3;&#x03ae;. &#x0395;&#x03ac;&#x03bd; &#x03b4;&#x03b5;&#x03bd; &#x03c3;&#x03c5;&#x03bc;&#x03c6;&#x03c9;&#x03bd;&#x03b5;&#x03af;&#x03c4;&#x03b5;, &#x03c0;&#x03b1;&#x03c4;&#x03ae;&#x03c3;&#x03c4;&#x03b5; <B>&#x0394;&#x03b5;&#x03bd; &#x03c3;&#x03c5;&#x03bc;&#x03c6;&#x03c9;&#x03bd;&#x03ce;</B>.',
			        'it':"Facendo clic su <B>Accetto</B>, si conferma (1) di aver avuto l'opportunit&#x00e0; di rivedere le clausole dell'accordo presentata di seguito e (2) che tali clausole regolano la presente transazione. Se non si accetta, fare clic su <B>Non accetto</B>.",
			        'in':'Dengan menekan tombol <b>Saya setuju</b>, Anda menyetujui bahwa (1) Anda memiliki kesempatan untuk meninjau syarat-syarat perjanjian yang diberikan di bawah ini dan (2) syarat-syarat tersebut mengatur transaksi ini. Apabila Anda tidak setuju, tekan tombol <b>Saya tidak setuju</b>.',
			        'ja':'&#x300c;<B>&#x540c;&#x610f;&#x3057;&#x307e;&#x3059;</B>&#x300d;&#x3092;&#x30af;&#x30ea;&#x30c3;&#x30af;&#x3059;&#x308b;&#x3053;&#x3068;&#x306b;&#x3088;&#x308a;&#x3001;&#x304a;&#x5ba2;&#x69d8;&#x306f;&#x6b21;&#x306e;&#x70b9;&#x306b;&#x3064;&#x304d;&#x540c;&#x610f;&#x3059;&#x308b;&#x3082;&#x306e;&#x3068;&#x3057;&#x307e;&#x3059;&#x3002; (1) &#x304a;&#x5ba2;&#x69d8;&#x304c;&#x4e0b;&#x8a18;&#x306b;&#x63d0;&#x793a;&#x3055;&#x308c;&#x308b;&#x4f7f;&#x7528;&#x6761;&#x4ef6;&#x3092;&#x78ba;&#x8a8d;&#x3059;&#x308b;&#x3053;&#x3068;&#x304c;&#x3067;&#x304d;&#x308b;&#x3053;&#x3068;&#x3002;(2) &#x3053;&#x306e;&#x30c8;&#x30e9;&#x30f3;&#x30b6;&#x30af;&#x30b7;&#x30e7;&#x30f3;&#x306f;&#x3001;&#x304b;&#x304b;&#x308b;&#x6761;&#x4ef6;&#x306b;&#x6e96;&#x62e0;&#x3059;&#x308b;&#x3082;&#x306e;&#x3067;&#x3042;&#x308b;&#x3053;&#x3068;&#x3002;&#x304a;&#x5ba2;&#x69d8;&#x304c;&#x540c;&#x610f;&#x3057;&#x306a;&#x3044;&#x5834;&#x5408;&#x306f;&#x3001;&#x300c;<B>&#x540c;&#x610f;&#x3057;&#x307e;&#x305b;&#x3093;</B>&#x300d;&#x3092;&#x30af;&#x30ea;&#x30c3;&#x30af;&#x3057;&#x3066;&#x304f;&#x3060;&#x3055;&#x3044;&#x3002;',
			        'ko':'&#xc18c;&#xd504;&#xd2b8;&#xc6e8;&#xc5b4; &#xb77c;&#xc774;&#xc13c;&#xc2a4; &#xacc4;&#xc57d;',
			        'lt':'Spustel&#x0117;dami <B>Sutinku</B>, j&#x016b;s sutinkate, kad (1) j&#x016b;s tur&#x0117;jote galimyb&#x0119; per&#x017e;i&#x016b;r&#x0117;ti toliau pateiktos sutarties s&#x0105;lygas ir (2) &#x0161;ios s&#x0105;lygos taikomos &#x0161;iai operacijai. Jei nesutinkate, spustel&#x0117;kite <B>Nesutinku</B>.',
			        'pl':'Klikaj&#x0105;c odsy&#x0142;acz <B>Zgadzam si&#x0119;</B>, U&#x017c;ytkownik (1) potwierdza, &#x017c;e mia&#x0142; mo&#x017c;liwo&#x015b;&#x0107; zapoznania si&#x0119; z warunkami umowy IBM, przedstawionymi poni&#x017c;ej, oraz (2) zgadza si&#x0119;, &#x017c;e warunkom tym podlega niniejsza transakcja. Je&#x015b;li U&#x017c;ytkownik nie wyra&#x017c;a zgody, powinien klikn&#x0105;&#x0107; odsy&#x0142;acz <B>Nie zgadzam si&#x0119;</B>.',
			        'pt':'Ao clicar em <B>Concordo</B>, o Cliente concorda que (1) teve a oportunidade de revisar os termos do contrato/acordo apresentado abaixo e (2) tais termos governam esta transa&#x00e7;&#x00e3;o/transac&#x00e7;&#x00e3;o. Se n&#x00e3;o concordar, clique em <B>N&#x00e3;o concordo</B>.',
			        'ru':'&#x0429;&#x0435;&#x043b;&#x043a;&#x043d;&#x0443;&#x0432; &#x043f;&#x043e; <B>&#x0421;&#x043e;&#x0433;&#x043b;&#x0430;&#x0441;&#x0435;&#x043d;</B>, &#x0432;&#x044b; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0448;&#x0430;&#x0435;&#x0442;&#x0435;&#x0441;&#x044c;, &#x0447;&#x0442;&#x043e; (1) &#x0432;&#x044b; &#x0438;&#x043c;&#x0435;&#x043b;&#x0438; &#x0432;&#x043e;&#x0437;&#x043c;&#x043e;&#x0436;&#x043d;&#x043e;&#x0441;&#x0442;&#x044c; &#x043f;&#x0440;&#x043e;&#x0432;&#x0435;&#x0440;&#x0438;&#x0442;&#x044c; &#x0443;&#x0441;&#x043b;&#x043e;&#x0432;&#x0438;&#x044f; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0448;&#x0435;&#x043d;&#x0438;&#x044f;, &#x043f;&#x0440;&#x0435;&#x0434;&#x0441;&#x0442;&#x0430;&#x0432;&#x043b;&#x0435;&#x043d;&#x043d;&#x044b;&#x0435; &#x043d;&#x0438;&#x0436;&#x0435;, &#x0438; (2) &#x0442;&#x0430;&#x043a;&#x0438;&#x0435; &#x0443;&#x0441;&#x043b;&#x043e;&#x0432;&#x0438;&#x044f; &#x0440;&#x0435;&#x0433;&#x0443;&#x043b;&#x0438;&#x0440;&#x0443;&#x044e;&#x0442; &#x0434;&#x0430;&#x043d;&#x043d;&#x0443;&#x044e; &#x0442;&#x0440;&#x0430;&#x043d;&#x0437;&#x0430;&#x043a;&#x0446;&#x0438;&#x044e;. &#x0415;&#x0441;&#x043b;&#x0438; &#x0432;&#x044b; &#x043d;&#x0435; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0441;&#x043d;&#x044b;, &#x0449;&#x0435;&#x043b;&#x043a;&#x043d;&#x0438;&#x0442;&#x0435; &#x043f;&#x043e; <B>&#x041d;&#x0435; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0441;&#x0435;&#x043d;</B>.',
			        'sl':'S klikom gumba <B>Sogla&#x0161;am</B> potrjujete, da (1) ste imeli prilo&#x017e;nost prebrati pogoje pogodbe, prikazane spodaj, in da (2) ti pogoji veljajo za to transakcijo. &#x010c;e ne sogla&#x0161;ate, kliknite <B>Ne sogla&#x0161;am</B>.',			        
			        'zh':'&#x5355;&#x51fb;<B>&#x6211;&#x540c;&#x610f;</B>&#xff0c;&#x5373;&#x8868;&#x793a;&#x60a8;&#x540c;&#x610f;&#xff1a;&#xff08;1&#xff09;&#x60a8;&#x5df2;&#x67e5;&#x9605;&#x8fc7;&#x4e0b;&#x9762;&#x6240;&#x63d0;&#x4f9b;&#x7684;&#x534f;&#x8bae;&#x4e2d;&#x7684;&#x6761;&#x6b3e;&#xff0c;&#x5e76;&#x4e14;&#xff08;2&#xff09;&#x6b64;&#x7c7b;&#x6761;&#x6b3e;&#x9002;&#x7528;&#x4e8e;&#x6b64;&#x9879;&#x4ea4;&#x6613;&#x3002;&#x5982;&#x679c;&#x60a8;&#x4e0d;&#x540c;&#x610f;&#xff0c;&#x8bf7;&#x5355;&#x51fb;<B>&#x6211;&#x4e0d;&#x540c;&#x610f;</B>&#x3002;',
			        'zh-tw':'&#x7576;  &#x8cb4;&#x5ba2;&#x6236;&#x6309;&#x4e00;&#x4e0b;<B>&#x6211;&#x540c;&#x610f;</B>&#x6642;&#xff0c;&#x5373;&#x8868;&#x793a;  &#x8cb4;&#x5ba2;&#x6236;&#x540c;&#x610f; (1) &#x8cb4;&#x5ba2;&#x6236;&#x66fe;&#x6709;&#x6a5f;&#x6703;&#x6aa2;&#x95b1;&#x4e0b;&#x5217;&#x5408;&#x7d04;&#x689d;&#x6b3e;&#xff0c;&#x4e14; (2) &#x6b64;&#x9805;&#x4ea4;&#x6613;&#x9700;&#x9075;&#x5faa;&#x6b64;&#x7b49;&#x689d;&#x6b3e;&#x3002;&#x82e5;  &#x8cb4;&#x5ba2;&#x6236;&#x4e0d;&#x540c;&#x610f;&#xff0c;&#x8acb;&#x6309;&#x4e00;&#x4e0b;<B>&#x6211;&#x4e0d;&#x540c;&#x610f;</B>&#x3002;',
			        'tr':'Kabul ediyorum</B> d&#x00fc;&#x011f;mesini t&#x0131;klatarak, (1) a&#x015f;a&#x011f;&#x0131;da sunulan s&#x00f6;zle&#x015f;menin ko&#x015f;ullar&#x0131;n&#x0131; inceledi&#x011f;inizi ve (2) bu i&#x015f;lemin bu ko&#x015f;ullara tabi olaca&#x011f;&#x0131;n&#x0131; kabul edersiniz. Kabul etmiyorsan&#x0131;z, <B>Kabul etmiyorum</B> d&#x00fc;&#x011f;mesini t&#x0131;klat&#x0131;n.'},
			    yesButton:{ //yes_caption
			    	'en':'Yes',
			        'cs':'Ano',
			        'fr':'Oui',
			        'de':'Ja',
			        'el':'&#x039d;&#x03b1;&#x03b9;',
			        'es':'S&#x00ed;',
			        'in':'Ya',
			        'it':'S&#x00ec;',
			        'ja':'&#x306f;&#x3044;',
			        'ko':'&#xc608;',
			        'lt':'Taip',
			        'pl':'Tak',
			        'pt':'Sim',
			        'ru':'&#x0414;&#x0430;',
			        'sl':'Da',			        
			        'zh':'&#x662f;',
			        'zh-tw':'&#x662f;',
			        'tr':'Evet'
			    },
			    noButton:{ //no_caption
			    	'en':'No',
			        'cs':'Ne',
			        'fr':'Non',
			        'de':'Nein',
			        'el':'&#x038c;&#x03c7;&#x03b9;',
			        'es':'No',
			        'in':'Tidak',
			        'it':'No',
			        'ja':'&#x3044;&#x3044;&#x3048;',
			        'ko':'&#xc544;&#xb2c8;&#xc624;',
			        'lt':'Ne',
			        'pl':'Nie',
			        'pt':'N&#x00e3;o',
			        'ru':'&#x041d;&#x0435;&#x0442;',
			        'sl':'Ne',			        
			        'zh':'&#x5426;',
			        'zh-tw':'&#x5426;',
			        'tr':'Hay&#x0131;r'
			    },
			    agreeButton:{//submit_caption
			    	'en':'I agree',
			        'cs':'Souhlas&#x00ed;m',
			        'fr':"J'accepte",
			        'de':'Anerkennen',
			        'el':'&#x03a3;&#x03c5;&#x03bc;&#x03c6;&#x03c9;&#x03bd;&#x03ce;',
			        'es':'Acepto',
			        'in':'Saya setuju',
			        'it':'Accetto',
			        'ja':'&#x540c;&#x610f;&#x3057;&#x307e;&#x3059;',
			        'ko':'&#xb3d9;&#xc758;&#xd568;',
			        'lt':'Sutinku',
			        'pl':'Zgadzam si&#x0119;',
			        'pt':'Concordo',
			        'ru':'&#x0421;&#x043e;&#x0433;&#x043b;&#x0430;&#x0441;&#x0435;&#x043d;',
			        'sl':'Sogla&#x0161;am',			        
			        'zh':'&#x6211;&#x540c;&#x610f;',
			        'zh-tw':'&#x6211;&#x540c;&#x610f;',
			        'tr':'Kabul ediyorum'},
			    declineButton:{//cancel_caption
			    	'en':'I do not agree',
			        'cs':'Nesouhlas&#x00ed;m',
			        'fr':'Je refuse',
			        'de':'Ablehnen',
			        'el':'&#x0394;&#x03b5;&#x03bd; &#x03c3;&#x03c5;&#x03bc;&#x03c6;&#x03c9;&#x03bd;&#x03ce;',
			        'es':'No acepto',
			        'in':'Saya tidak setuju',
			        'it':'Non accetto',
			        'ja':'&#x540c;&#x610f;&#x3057;&#x307e;&#x305b;&#x3093;',
			        'ko':'&#xb3d9;&#xc758;&#xd558;&#xc9c0; &#xc54a;&#xc74c;',
			        'lt':'Nesutinku',
			        'pl':'Nie zgadzam si&#x0119;',
			        'pt':'N&#x00e3;o concordo',
			        'ru':'&#x041d;&#x0435; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0441;&#x0435;&#x043d;',
			        'sl':'Ne sogla&#x0161;am',
			        'zh':'&#x6211;&#x4e0d;&#x540c;&#x610f;',
			        'zh-tw':'&#x6211;&#x4e0d;&#x540c;&#x610f;',
			        'tr':'Kabul etmiyorum'},
			        confirmDeclineMessage:{ //confirm_text2
			        	'en':'Do you really wish to decline the agreement?',
				        'cs':'Chcete skute&#x010d;n&#x011b; odm&#x00ed;tnout smlouvu?',
				        'fr':'Voulez-vous vraiment refuser le Contrat ?',
				        'de':'M&#x00f6;chten Sie die Vereinbarung wirklich ablehnen?',
				        'el':'&#x0395;&#x03af;&#x03c3;&#x03c4;&#x03b5; &#x03b2;&#x03ad;&#x03b2;&#x03b1;&#x03b9;&#x03bf;&#x03b9; &#x03cc;&#x03c4;&#x03b9; &#x03b8;&#x03ad;&#x03bb;&#x03b5;&#x03c4;&#x03b5; &#x03bd;&#x03b1; &#x03b1;&#x03c0;&#x03bf;&#x03c1;&#x03c1;&#x03af;&#x03c8;&#x03b5;&#x03c4;&#x03b5; &#x03c4;&#x03b7; &#x03c3;&#x03cd;&#x03bc;&#x03b2;&#x03b1;&#x03c3;&#x03b7;;',
				        'es':'&#x00bf;Est&#x00e1; seguro de que desea rechazar el acuerdo?',
				        'in':'Apakah Anda benar-benar tidak menyetujui perjanjian ini?',
				        'it':"Si desidera veramente rifiutare l'accordo?",
				        'ja':'&#x3053;&#x306e;&#x4f7f;&#x7528;&#x6761;&#x4ef6;&#x306b;&#x540c;&#x610f;&#x3057;&#x306a;&#x3044;&#x3067;&#x3088;&#x308d;&#x3057;&#x3044;&#x3067;&#x3059;&#x304b;?',
				        'ko':'&#xacc4;&#xc57d;&#xc5d0; &#xb3d9;&#xc758;&#xd558;&#xc9c0; &#xc54a;&#xc2b5;&#xb2c8;&#xae4c;?',
				        'lt':'J&#x016b;s pasirinkote atmesti sutart&#x012f;. Programos atsisiuntimas nebaigtas.',
				        'pl':'Czy na pewno chcesz odrzuci&#x0107; umow&#x0119;?',
				        'pt':'Tem certeza de que deseja realmente recusar o contrato/acordo?',
				        'ru':'&#x0412;&#x044b; &#x0440;&#x0435;&#x0448;&#x0438;&#x043b;&#x0438; &#x043e;&#x0442;&#x043a;&#x043b;&#x043e;&#x043d;&#x0438;&#x0442;&#x044c; &#x0441;&#x043e;&#x0433;&#x043b;&#x0430;&#x0448;&#x0435;&#x043d;&#x0438;&#x0435;. &#x0417;&#x0430;&#x0433;&#x0440;&#x0443;&#x0437;&#x043a;&#x0430; &#x043f;&#x0440;&#x043e;&#x0433;&#x0440;&#x0430;&#x043c;&#x043c;&#x044b; &#x043d;&#x0435; &#x0431;&#x044b;&#x043b;&#x0430; &#x0437;&#x0430;&#x0432;&#x0435;&#x0440;&#x0448;&#x0435;&#x043d;&#x0430;.',
				        'sl':'Ali res &#x017e;elite zavrniti pogodbo?',
				        'zh':'&#x662f;&#x5426;&#x786e;&#x5b9e;&#x8981;&#x62d2;&#x7edd;&#x672c;&#x534f;&#x8bae;&#xff1f;',
				        'zh-tw':'&#x60a8;&#x771f;&#x7684;&#x8981;&#x62d2;&#x7d55;&#x672c;&#x5408;&#x7d04;&#x55ce;&#xff1f;',
				        'tr':'S&#x00f6;zle&#x015f;meyi reddetmeyi istedi&#x011f;inizden emin misiniz?'}};

		this.supportedLocale="en";
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.panel","panelstrings");
		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug(" License Panel postCreate is called...");			
		this.inherited("postCreate",arguments);				
		//In Test, make sure to copy license files to this location here
		console.debug("execEnvISADevEnv?: "+this.execEnvISADevEnv + " IsFile? "+ this.execEnvIsFile);
		this.licensesBaseLocation="";
		if(this.execEnvISADevEnv && this.execEnvIsFile){ //Base location from the dev. environment, pick up licenses from another project
			this.licensesBaseLocation=getBaseLocation(); //If testing from the test_licensePanel.html, change to getBaseLocation()+../../
		}else {
			this.licensesBaseLocation=getBaseLocation();
		}

		//Main Dialog wrapperLabel Div
		var wrapperLabelDiv = dojo.create('div');
		
		this.currentLocale=this._getLocale();
		
		//Software Agreement Section
		var licenseAgreementDiv= dojo.create('div',{style:"margin-top:5px; margin-left:10px; text-align:left"});		
		var licenseAgreement=this._getLocalizedString('sofwareLicenseAgreement',this.currentLocale);		
		var licenseAgreementLabel=dojo.create('h1',{id:'licenseAgreementLabelID',innerHTML:licenseAgreement});
		licenseAgreementDiv.appendChild(licenseAgreementLabel);
				 

		//Software Message Section 
		var agreeDeclineDiv= dojo.create('div',{style:"margin-top:5px; margin-left:10px; text-align:left"});		
		var agreeDeclineMessage=this._getLocalizedString('agreeDeclineMessage',this.currentLocale);		
		var agreeDeclineLabel=dojo.create('label',{id:'agreeDeclineMessageID',innerHTML:agreeDeclineMessage});
		agreeDeclineDiv.appendChild(agreeDeclineLabel);

		var localeSelectionDiv = dojo.create('div',{style:"margin-top:5px; margin-left:10px; text-align:left"});

		//Combobox with list of languages to select from
	    this.licenseLocales=new dijit.form.Select({name: 'select2',	maxHeight:200,style:"width: 150px;"});
	    
	    //Filling the Combo Box with the languages. Languages labels have to be localized
	    var localeLabels=this._getLocalLabels(this.currentLocale);
		for(var i=0; i < this.localeSupported.length; i++) {			
		  	this.licenseLocales.addOption({"label":localeLabels[i],"value":this.localeSupported[i]});
		}
		
	    localeSelectionDiv.appendChild(this.licenseLocales.domNode);

	    //Wrapper for the license html display section
		var licenseHTMLContainer = dojo.create('div', {style:"width:530px;height:300px;overflow:auto;align:left;valign:top"});
		
		//
        var htmlLicenseSuffix=this._getLocale();
        if(htmlLicenseSuffix=="zh-tw"){
      	      htmlLicenseSuffix='zh_TW';  
        }

		//Handling the zh-tw locale differently. TODO: Ask about pt_BR?
		var licenseHTMLRef=this.licensesBaseLocation+"licenses/LA_" + htmlLicenseSuffix + ".html";
		
		this.licenseContentPane= new dijit.layout.ContentPane({href:licenseHTMLRef,style:'overflow:auto;text-align:left;valign:top'});
				
		licenseHTMLContainer.appendChild(this.licenseContentPane.domNode);
		
		var buttonWrapper = dojo.create('div');

		var buttonsDiv = dojo.create('div',{style:{margin:'20px 0 0 0'}});
		var agreeLicenseMessage = this._getLocalizedString('agreeButton',this.currentLocale);
		var agreeLicenseButton = new dijit.form.Button({id:'agreeLicenseButtonID',label:agreeLicenseMessage, disabled:false,style:{margin:'0px 0 0 20px'},
			                                     baseClass:'isa-ibm-btn-arrow-pri'});
		buttonsDiv.appendChild(agreeLicenseButton.domNode);
		
		var declineLicenseMessage = this._getLocalizedString('declineButton',this.currentLocale);
		var declineLicenseButton = new dijit.form.Button({id:'declineLicenseButtonID',label:declineLicenseMessage, disabled:false, style:{margin:'0px 0 0 50px'},
			                                       baseClass:'isa-ibm-btn-arrow-pri'});
		buttonsDiv.appendChild(declineLicenseButton.domNode);
		
		//Horizontal seperator
		var horizontalLineDiv = dojo.create('hr',{style:{margin:'10px 0px 0px 0px'}});

		//Add the divs to the main page
	    buttonWrapper.appendChild(licenseAgreementDiv);
	    buttonWrapper.appendChild(agreeDeclineDiv);
        buttonWrapper.appendChild(localeSelectionDiv);
        buttonWrapper.appendChild(horizontalLineDiv);
	    buttonWrapper.appendChild(licenseHTMLContainer);	     		
		buttonWrapper.appendChild(buttonsDiv);

		//Create the Dialog to contain all the elements
	    this.dialog= new dijit.Dialog({
				title:'',
				draggable:false,
				style: {
					width: "550px"
				}
			});

	    //Title of the Dialog
	    var licenseAcceptanceTitle = this._getLocalizedString("sofwareLicenseAgreement",this.currentLocale);
	    this.dialog.set('title', licenseAcceptanceTitle);

	    //License was accepted by Customer.
		dojo.connect(agreeLicenseButton,"onClick",this,dojo.hitch(this,this._agreeLicenseTerms));

		//License was declined by Customer
		dojo.connect(declineLicenseButton,"onClick",this,dojo.hitch(this,this._declineLicenseTerms));
		
		//Topright x clicked.
		dojo.connect(this.dialog,"onCancel",this,dojo.hitch(this,this._declineLicenseTerms));
		
	    //Language Selector Events
		dojo.connect(this.licenseLocales,"onChange",this,dojo.hitch(this,this._selectAnotherLanguage));

		wrapperLabelDiv.appendChild(buttonWrapper);
	    dojo.attr(this.dialog,"content",wrapperLabelDiv);

	    console.debug(" Showing the dialog with id: "+this.dialog.id);
		this.dialog.show(); 

	},
	//
	//
	//
	_selectAnotherLanguage:function(event){
    	
	          console.debug("Locale was modified to "+event);			
	          var localeSelected=event;
	          var htmlLicenseSuffix=localeSelected;
	          if(localeSelected=="zh-tw"){
	        	htmlLicenseSuffix='zh_TW';  
	          }
	          var newLicenseAgreement = this._getLocalizedString('sofwareLicenseAgreement',localeSelected);
	          var newAgreeDeclineMessage=this._getLocalizedString('agreeDeclineMessage',localeSelected);
	          var newLicenseHTMLRef=this.licensesBaseLocation+"licenses/LA_" + htmlLicenseSuffix + ".html";
	  		  var newAgreeLicenseMessage = this._getLocalizedString('agreeButton',localeSelected);
	  		  var newDeclineLicenseMessage = this._getLocalizedString('declineButton',localeSelected);
	  	      var newLicenseAcceptanceTitle = this._getLocalizedString("sofwareLicenseAgreement",localeSelected);
		      this.currentLocale=localeSelected;

		      var localeLabels=this._getLocalLabels(this.currentLocale);
			  for (var i=0; i < this.localeSupported.length; i++) {
				  this.licenseLocales.updateOption({"label":localeLabels[i],"value":this.localeSupported[i]});
				}

	          
	          dijit.byId(this.licenseContentPane.id).set('href',newLicenseHTMLRef);	 
	          dojo.byId("licenseAgreementLabelID").innerHTML=newLicenseAgreement;
	          dojo.byId("agreeDeclineMessageID").innerHTML=newAgreeDeclineMessage;
	          dijit.byId("agreeLicenseButtonID").set('label',newAgreeLicenseMessage);
	          dijit.byId("declineLicenseButtonID").set('label',newDeclineLicenseMessage);
	          dijit.byId(this.dialog.id).set('title',newLicenseAcceptanceTitle);
          
	},
	//
	//
	//
	_agreeLicenseTerms:function(){
		//
		// Summary:
		//
		//Hide and destroy the dialog
		this.dialog.hide();
		dojo.destroy(this.dialog);
		console.debug("The license was accepted.");

		//Publish an event that the license has been accepted.
		dojo.publish("LicenseAcceptedByCustomer", []);	
	},
	//
	//Declining the license terms has been selected. Give the user one more change to come back
	//
	_declineLicenseTerms:function(){
		//
		// Summary:Displays Dialog box giving customer change to confirm his/her selection
		//		
		var confirmMessage = this._getLocalizedString('confirmDeclineMessage',this.currentLocale);

		var wrapperDiv = dojo.create('div');
		var confirmMessageDiv = dojo.create('div',{style:{}});
		var confirmMessageLabel=dojo.create('label',{id:'confirmMessageLabelID',innerHTML:confirmMessage});
		confirmMessageDiv.appendChild(confirmMessageLabel);

		//var buttonWrapper = dojo.create('div');

		var buttonsDiv = dojo.create('div',{style:{margin:'20px 0 0 0'}});
		var yesMessage = this._getLocalizedString('yesButton',this.currentLocale);
		var yesLicenseButton = new dijit.form.Button({label:yesMessage, disabled:false, style:{margin:'0px 0 0 20px'},
			                                                baseClass:'isa-ibm-btn-arrow-pri'});
		buttonsDiv.appendChild(yesLicenseButton.domNode);
		
		var noMessage = this._getLocalizedString('noButton',this.currentLocale);
		var noLicenseButton = new dijit.form.Button({label:noMessage, disabled:false,style:{margin:'0px 0 0 50px'},
			                                     baseClass:'isa-ibm-btn-arrow-pri'});
		buttonsDiv.appendChild(noLicenseButton.domNode);

		console.debug("License agreement was declined by Customer. ");
		
		//Create the Dialog to contain the confirmation message
	    var confirmDialog= new dijit.Dialog({
				title:'',
				draggable:false,
				style: {
					width: "300px"
				}
			});
	    	    
	    //Title of the Dialog
	    var confirmDialogTitle = this._getLocalizedString("sofwareLicenseAgreement",this.currentLocale);
	    confirmDialog.set('title', confirmDialogTitle);

	    wrapperDiv.appendChild(confirmMessageDiv);
	    wrapperDiv.appendChild(buttonsDiv);
	    dojo.attr(confirmDialog,"content",wrapperDiv);

	    //Customer confirms they are refusing the contract
		dojo.connect(yesLicenseButton,"onClick",this,dojo.hitch(this,function(){
			console.debug("Yes was clicked. Customer confirms, they are refusing the contract.");
			var stack = dijit.byId("mainViewStackContainerID"); 
			dijit.byId("noLicenseContent").set("content",this.noLicenseCompletedMessage);
			confirmDialog.hide();
			dojo.destroy(confirmDialog);
			this.dialog.hide();
			dojo.destroy(this.dialog);
			
			stack.forward();

		}));

		//Customer doesn't want to decline the contract. Go back to beginning
		dojo.connect(noLicenseButton,"onClick",this,dojo.hitch(this,function(){
			console.debug("No was clicked. Customer doesn't confirm refusal of contract.  Give him another chance");
			//Check the status of this.dialog
			confirmDialog.hide();
			dojo.destroy(confirmDialog);
			//Hide and destroy the dialog
			this.dialog.show();

		}));
		
		//Topright x clicked. Same as No was clicked. Back to beginning
		dojo.connect(confirmDialog,"onCancel",this,dojo.hitch(this,function(){
			console.debug("x on top right corner of Dialog box was selected");
			//Hide and destroy the dialog
			confirmDialog.hide();
			dojo.destroy(confirmDialog);
		}));

	    confirmDialog.show(); 
		
	},
	_getLocalLabels:function(locale){
		//this.localeSupported=["cs","de","el","en","es","fr","in","it","ja","ko","lt","pl","pt","ru","sl","tr","zh","zh-tw"];
		if(locale=="en") 
			return ["English(en)","Czech(cs)","German(de)","Greek(el)","Spanish(es)","French(fr)","Indonesian(in)",
			        "Italian(it)","Japanese(ja)","Korean(ko)","Lithuanian(lt)","Polish(pl)","Portuguese(pt)","Russian(ru)",
			        "Slovenan (sl)","Turkish(tr)","Simplified Chinese(zh)","Traditional Chinese (zh-tw)"];
		
		if(locale=="cs") 
			return ["angli&#x010d;tina(en)","&#x010d;e&#x0161;tina(cs)","n&#x011b;m&#x010d;ina(de)","&#x0159;e&#x010d;tina(el)","&#x0161;pan&#x011b;l&#x0161;tina(es)",
			        "francouz&#x0161;tina(fr)","indon&#x00e9;&#x0161;tina(in)","ital&#x0161;tina(it)","japon&#x0161;tina(ja)",
			        "korej&#x0161;tina(ko)","litev&#x0161;tina(lt)","pol&#x0161;tina(pl)","portugal&#x0161;tina(pt)","ru&#x0161;tina(ru)",
			        "slovin&#x0161;tina(sl)","ture&#x010d;tina(tr)","zjednodu&#x0161;en&#x00e1; &#x010d;&#x00ed;n&#x0161;tina(zh)","tradi&#x010d;n&#x00ed; &#x010d;&#x00ed;n&#x0161;tina(zh-tw)"];
		
		if(locale=="de") 
			return ["English(en)","Tschechisch(cs)","Deutsch(de)","Griechisch(el)","Spanisch(es)","Franz&#x00f6;sisch(fr)","Indonesisch(in)",
			        "Italienisch(it)","Japanisch(ja)","Koreanisch(ko)","Litauisch(lt)","Polnisch(pl)","Portugiesisch(pt)","Russisch(ru)",
			        "slov&#x00e8;ne(sl)","T&#x00fc;rkisch(tr)","Vereinfachtes Chinesisch(zh)","Traditionelles Chinesisch(zh-tw)"];
		
		if(locale=="el") 
			return ["&#x0391;&#x03b3;&#x03b3;&#x03bb;&#x03b9;&#x03ba;&#x03ac;(en)","&#x03a4;&#x03c3;&#x03b5;&#x03c7;&#x03b9;&#x03ba;&#x03ac;(cs)","&#x0393;&#x03b5;&#x03c1;&#x03bc;&#x03b1;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(de)","&#x0395;&#x03bb;&#x03bb;&#x03b7;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(el)",
			        "&#x0399;&#x03c3;&#x03c0;&#x03b1;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(es)","&#x0393;&#x03b1;&#x03bb;&#x03bb;&#x03b9;&#x03ba;&#x03ac;(fr)","&#x0399;&#x03bd;&#x03b4;&#x03bf;&#x03bd;&#x03b7;&#x03c3;&#x03b9;&#x03b1;&#x03ba;&#x03ac;(in)",
			        "&#x0399;&#x03c4;&#x03b1;&#x03bb;&#x03b9;&#x03ba;&#x03ac;(it)","&#x0399;&#x03b1;&#x03c0;&#x03c9;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(ja)","&#x039a;&#x03bf;&#x03c1;&#x03b5;&#x03b1;&#x03c4;&#x03b9;&#x03ba;&#x03ac;;en(ko)",
			        "&#x039b;&#x03b9;&#x03b8;&#x03bf;&#x03c5;&#x03b1;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(lt)","&#x03a0;&#x03bf;&#x03bb;&#x03c9;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(pl)","&#x03a0;&#x03bf;&#x03c1;&#x03c4;&#x03bf;&#x03b3;&#x03b1;&#x03bb;&#x03b9;&#x03ba;&#x03ac;(pt)","&#x03a1;&#x03c9;&#x03c3;&#x03b9;&#x03ba;&#x03ac;(ru)",
			        "&#x03a3;&#x03bb;&#x03bf;&#x03b2;&#x03b5;&#x03bd;&#x03b9;&#x03ba;&#x03ac;(sl)","&#x03a4;&#x03bf;&#x03c5;&#x03c1;&#x03ba;&#x03b9;&#x03ba;&#x03ac;(tr)","&#x039a;&#x03b9;&#x03bd;&#x03b5;&#x03b6;&#x03b9;&#x03ba;&#x03ac; &#x0391;&#x03c0;&#x03bb;&#x03bf;&#x03c0;&#x03bf;&#x03b9;&#x03b7;&#x03bc;&#x03ad;&#x03bd;&#x03b1;(zh)",
			        "&#x039a;&#x03b9;&#x03bd;&#x03b5;&#x03b6;&#x03b9;&#x03ba;&#x03ac; &#x03a0;&#x03b1;&#x03c1;&#x03b1;&#x03b4;&#x03bf;&#x03c3;&#x03b9;&#x03b1;&#x03ba;&#x03ac;(zh-tw)"];
		
		if(locale=="es") 
			return ["Ingl&#x00e9;s(en)","Checo(cs)","Alem&#x00e1;n(de)","Griego(el)","Espa&#x00f1;ol(es)","Franc&#x00e9;s(fr)","Indonesio(in)",
			        "Italiano(it)","Japon&#x00e9;s(ja)","Coreano(ko)","Lituano(lt)","Polaco(pl)","Portugu&#x00e9;s(pt)","Ruso(ru)",
			        "Esloveno(sl)","Turco(tr)","Chino simplificado(zh)","Chino tradicional(zh-tw)"];

		if(locale=="fr") 
			return ["anglais(en)","tch&#x00e8;que(cs)","allemand(de)","grec(el)","espagnol(es)","fran&#x00e7;ais(fr)","indon&#x00e9;sien(in)",
			        "italien(it)","japonais(ja)","cor&#x00e9;en(ko)","lituanien(lt)","polonais(pl)","portugais(pt)","russe(ru)",
			        "slov&#x00e8;ne(sl)","turc(tr)","chinois simplifi&#x00e9;(zh)","chinois traditionnel(zh-tw)"];
				
		if(locale=="in") 
			return ["Inggris(en)","Ceska(cs)","Jerman(de)","Yunani(el)","Spanyol(es)","Prancis(fr)","Indonesia(in)",
			        "Italia(it)","Jepang(ja)","Korea(ko)","Lituania(lt)","Polandia(pl)","Portugis(pt)","Rusia(ru)",
			        "Slovenia(sl)","Turki(tr)","Cina Modern(zh)","Cina Tradisional(zh-tw)"];
		
		if(locale=="it") 
			return ["Inglese(en)","Ceco(cs)","Tedesco(de)","Greco(el)","Spagnolo(es)","Francese(fr)","Indonesiano(in)",
			        "Italiano(it)","Giapponese(ja)","Coreano(ko)","Lituano(lt)","Polacco(pl)","Portoghese(pt)","Russo(ru)",
			        "Sloveno(sl)","Turco(tr)","Cinese Semplificato(zh)","Cinese Tradizionale(zh-tw)"];

		if(locale=="ja") 
			return ["&#x82f1;&#x8a9e;(en)","&#x30c1;&#x30a7;&#x30b3;&#x8a9e;(cs)","&#x30c9;&#x30a4;&#x30c4;&#x8a9e;(de)","&#x30ae;&#x30ea;&#x30b7;&#x30e3;&#x8a9e;(el)","&#x30b9;&#x30da;&#x30a4;&#x30f3;&#x8a9e;(es)",
			        "&#x30d5;&#x30e9;&#x30f3;&#x30b9;&#x8a9e;(fr)","&#x30a4;&#x30f3;&#x30c9;&#x30cd;&#x30b7;&#x30a2;&#x8a9e;(in)",
			        "&#x30a4;&#x30bf;&#x30ea;&#x30a2;&#x8a9e;(it)","&#x65e5;&#x672c;&#x8a9e;(ja)","&#x97d3;&#x56fd;&#x8a9e;(ko)","&#x30ea;&#x30c8;&#x30a2;&#x30cb;&#x30a2;&#x8a9e;(lt)"
			        ,"&#x30dd;&#x30fc;&#x30e9;&#x30f3;&#x30c9;&#x8a9e;(pl)","&#x30dd;&#x30eb;&#x30c8;&#x30ac;&#x30eb;&#x8a9e;(pt)","&#x30ed;&#x30b7;&#x30a2;&#x8a9e;(ru)",
			        "&#x30b9;&#x30ed;&#x30d9;&#x30cb;&#x30a2;&#x8a9e;(sl)","&#x30c8;&#x30eb;&#x30b3;&#x8a9e;(tr)","&#x4e2d;&#x56fd;&#x8a9e; (&#x7c21;&#x4f53;&#x5b57;)(zh)",
			        "&#x4e2d;&#x56fd;&#x8a9e; (&#x7e41;&#x4f53;&#x5b57;)(zh-tw)"];
		
        if(locale=="tr")
		    return ["&#x0130;ngilizce(en)","&#x00c7;ek&#x00e7;e(cs)","Almanca(de)","Yunanca(el)","&#x0130;spanyolca(es)","Frans&#x0131;zca(fr)","Endonezya Dili(in)",
	    			"&#x0130;talyanca(it)","Japonca(ja)","Korece(ko)","Litvanya dili(lt)","Leh&#x00e7;e(pl)","Portekizce(pt)","Rus&#x00e7;a(ru)",
	    			"Slovence (sl)","T&#x00fc;rk&#x00e7;e(tr)","Basitle&#x015f;tirilmi&#x015f; &#x00c7;ince(zh)","Geleneksel &#x00c7;ince(zh-tw)"];

		if(locale=="ko") 
			return ["&#xc601;&#xc5b4;(en)","&#xccb4;&#xcf54;&#xc5b4;(cs)","&#xb3c5;&#xc77c;&#xc5b4;(de)","&#xadf8;&#xb9ac;&#xc2a4;&#xc5b4;(el)","&#xc2a4;&#xd398;&#xc778;&#xc5b4;(es)",
			        "&#xd504;&#xb791;&#xc2a4;&#xc5b4;(fr)","&#xc778;&#xb3c4;&#xb124;&#xc2dc;&#xc544;&#xc5b4;(in)","&#xc774;&#xd0c8;&#xb9ac;&#xc544;&#xc5b4;(it)","&#xc77c;&#xbcf8;&#xc5b4;(ja)",
			        "&#xd55c;&#xad6d;&#xc5b4;(ko)","&#xb9ac;&#xd22c;&#xc544;&#xb2c8;&#xc544;&#xc5b4;(lt)","&#xd3f4;&#xb780;&#xb4dc;&#xc5b4;(pl)",
			        "&#xd3ec;&#xb974;&#xd22c;&#xac08;&#xc5b4;(pt)","&#xb7ec;&#xc2dc;&#xc544;&#xc5b4;(ru)",
			        "&#xc2ac;&#xb85c;&#xbca0;&#xb2c8;&#xc544;&#xc5b4;(sl)","&#xd130;&#xd0a4;&#xc5b4;(tr)","&#xc911;&#xad6d;&#xc5b4;(zh)","&#xb300;&#xb9cc;&#xc5b4;(zh-tw)"];
						
		if(locale=="lt") 
			return ["Angl&#x0173;(en)","&#x010c;ek&#x0173;(cs)","Vokie&#x010d;i&#x0173;(de)","Graik&#x0173;(el)","Ispan&#x0173;(es)","Pranc&#x016b;z&#x0173;(fr)",
			        "Indonezie&#x010d;i&#x0173;(in)","Ital&#x0173;(it)","Japon&#x0173;(ja)","Kor&#x0117;jie&#x010d;i&#x0173;(ko)","Lietuvi&#x0173;(lt)",
			        "Lenk&#x0173;(pl)","Portugal&#x0173;(pt)", "Rus&#x0173;(ru)", "Slov&#x0117;n&#x0173;(sl)","Turk&#x0173;(tr)",
			        "Supaprastinta kin&#x0173;(zh)","Tradicin&#x0117; kin&#x0173;(zh-tw)"];
						
		if(locale=="pl") 
			return ["Hiszpa&#x0144;ski(es)","Czeski(cs)","Niemiecki(de)","Grecki(el)","Angielski(en)","Francuski(fr)","Indonezyjski(in)",
			        "W&#x0142;oski(it)","Japo&#x0144;ski(ja)","Korea&#x0144;ski(ko)","Litewski(lt)","Polski(pl)","Portugalski(pt)","Rosyjski(ru)",
			        "S&#x0142;owe&#x0144;ski(sl)","Turecki(tr)","Chi&#x0144;ski uproszczony(zh)","Chi&#x0144;ski tradycyjny(zh-tw)"];
		
		if(locale=="pt") 
			return ["Ingl&#x00ea;s(en)","Tcheco(cs)","Alem&#x00e3;o(de)","Grego(el)","Espanhol(es)","Franc&#x00ea;s(fr)","Indon&#x00e9;sio(in)",
			        "Italiano(it)","Japon&#x00ea;s(ja)","Coreano(ko)","Lituano(lt)","Polon&#x00ea;s(pl)","Portugu&#x00ea;s(pt)","Russo(ru)",
			        "Esloveno (sl)","Turco(tr)","Chin&#x00ea;s Simplificado(zh)","Chin&#x00ea;s Tradicional(zh-tw)"];
		
        if(locale=="ru")
	        return ["&#x0410;&#x043d;&#x0433;&#x043b;&#x0438;&#x0439;&#x0441;&#x043a;&#x0438;&#x0439;(en)","&#x0427;&#x0435;&#x0448;&#x0441;&#x043a;&#x0438;&#x0439;(cs)","&#x041d;&#x0435;&#x043c;&#x0435;&#x0446;&#x043a;&#x0438;&#x0439;(de)","&#x0413;&#x0440;&#x0435;&#x0447;&#x0435;&#x0441;&#x043a;&#x0438;&#x0439;(el)",
	                "&#x0418;&#x0441;&#x043f;&#x0430;&#x043d;&#x0441;&#x043a;&#x0438;&#x0439;(es)","&#x0424;&#x0440;&#x0430;&#x043d;&#x0446;&#x0443;&#x0437;&#x0441;&#x043a;&#x0438;&#x0439;(fr)","&#x0418;&#x043d;&#x0434;&#x043e;&#x043d;&#x0435;&#x0437;&#x0438;&#x0439;&#x0441;&#x043a;&#x0438;&#x0439;(in)",
                    "&#x0418;&#x0442;&#x0430;&#x043b;&#x044c;&#x044f;&#x043d;&#x0441;&#x043a;&#x0438;&#x0439;(it)","&#x042f;&#x043f;&#x043e;&#x043d;&#x0441;&#x043a;&#x0438;&#x0439;(ja)","&#x041a;&#x043e;&#x0440;&#x0435;&#x0439;&#x0441;&#x043a;&#x0438;&#x0439;(ko)",
                    "&#x041b;&#x0438;&#x0442;&#x043e;&#x0432;&#x0441;&#x043a;&#x0438;&#x0439;(lt)","&#x041f;&#x043e;&#x043b;&#x044c;&#x0441;&#x043a;&#x0438;&#x0439;(pl)","&#x041f;&#x043e;&#x0440;&#x0442;&#x0443;&#x0433;&#x0430;&#x043b;&#x044c;&#x0441;&#x043a;&#x0438;&#x0439;(pt)","&#x0420;&#x0443;&#x0441;&#x0441;&#x043a;&#x0438;&#x0439;(ru)",
                    "&#x0421;&#x043b;&#x043e;&#x0432;&#x0435;&#x043d;&#x0441;&#x043a;&#x0438;&#x0439;(sl)","&#x0422;&#x0443;&#x0440;&#x0435;&#x0446;&#x043a;&#x0438;&#x0439;(tr)",
                    "&#x041a;&#x0438;&#x0442;&#x0430;&#x0439;&#x0441;&#x043a;&#x0438;&#x0439; &#x0443;&#x043f;&#x0440;&#x043e;&#x0449;&#x0435;&#x043d;&#x043d;&#x044b;&#x0439;(zh)",
                    "&#x041a;&#x0438;&#x0442;&#x0430;&#x0439;&#x0441;&#x043a;&#x0438;&#x0439; &#x0442;&#x0440;&#x0430;&#x0434;&#x0438;&#x0446;&#x0438;&#x043e;&#x043d;&#x043d;&#x044b;&#x0439;(zh-tw)"];

        if(locale=="sl")
	        return ["Angle&#x0161;&#x010d;ina(en)","&#x010c;e&#x0161;&#x010d;ina(cs)","Nem&#x0161;&#x010d;ina(de)","Gr&#x0161;&#x010d;ina(el)","&#x0160;pan&#x0161;&#x010d;ina(es)","Franco&#x0161;&#x010d;ina(fr)","Indonezij&#x0161;&#x010d;ina(in)",
                    "Italijan&#x0161;&#x010d;ina(it)","Japon&#x0161;&#x010d;ina(ja)","Korej&#x0161;&#x010d;ina(ko)","Litov&#x0161;&#x010d;ina(lt)","Polj&#x0161;&#x010d;ina(pl)","Portugal&#x0161;&#x010d;ina(pt)","Ru&#x0161;&#x010d;ina(ru)",
                    "Sloven&#x0161;&#x010d;ina(sl)","Tur&#x0161;&#x010d;ina(tr)","Poenostavljena kitaj&#x0161;&#x010d;ina(zh)","Tradicionalna kitaj&#x0161;&#x010d;ina(zh-tw)"];

        if(locale=="zh")
	        return ["&#x82f1;&#x8bed;(en)","&#x6377;&#x514b;&#x8bed;(cs)","&#x5fb7;&#x8bed;(de)","&#x5e0c;&#x814a;&#x8bed;(el)","&#x897f;&#x73ed;&#x7259;&#x8bed;(es)","&#x6cd5;&#x8bed;(fr)","&#x5370;&#x5ea6;&#x5c3c;&#x897f;&#x4e9a;&#x8bed;(in)",
                    "&#x610f;&#x5927;&#x5229;&#x8bed;(it)","&#x65e5;&#x8bed;(ja)","&#x97e9;&#x56fd;&#x8bed;(ko)","&#x7acb;&#x9676;&#x5b9b;&#x8bed;(lt)","&#x6ce2;&#x5170;&#x8bed;(pl)",
                    "&#x8461;&#x8404;&#x7259;&#x8bed;(pt)","&#x4fc4;&#x8bed;(ru)",
                    "&#x65af;&#x6d1b;&#x6587;&#x5c3c;&#x4e9a;&#x8bed; (sl)","&#x571f;&#x8033;&#x5176;&#x8bed;(tr)","&#x7b80;&#x4f53;&#x4e2d;&#x6587;(zh)","&#x7e41;&#x4f53;&#x4e2d;&#x6587;(zh-tw)"];
        
        if(locale=="zh-tw")
	        return ["&#x82f1;&#x6587;(en)","&#x6377;&#x514b;&#x6587;(cs)","&#x5fb7;&#x6587;(de)","&#x5e0c;&#x81d8;&#x6587;(el)","&#x897f;&#x73ed;&#x7259;&#x6587;(es)","&#x6cd5;&#x6587;(fr)","&#x5370;&#x5c3c;&#x6587;(in)",
                    "&#x7fa9;&#x5927;&#x5229;&#x6587;(it)","&#x65e5;&#x6587;(ja)","&#x97d3;&#x6587;(ko)","&#x7acb;&#x9676;&#x5b9b;&#x6587;(lt)","&#x6ce2;&#x862d;&#x6587;(pl)","&#x8461;&#x8404;&#x7259;&#x6587;(pt)","&#x4fc4;&#x6587;(ru)",
                    "&#x65af;&#x6d1b;&#x7dad;&#x5c3c;&#x4e9e;&#x6587; (sl)","&#x571f;&#x8033;&#x5176;&#x6587;(tr)","&#x7c21;&#x9ad4;&#x4e2d;&#x6587;(zh)","&#x7e41;&#x9ad4;&#x4e2d;&#x6587;(zh-tw)"];

		else  //return English
			return ["Czech(cs)","German(de)","Greek(el)","English(en)","Spanish(es)","French(fr)","Indonesian(in)",
			        "Italian(it)","Japanese(ja)","Korean(ko)","Lithuanian(lt)","Polish(pl)","Portuguese(pt)","Russian(ru)",
			        "Slovenan (sl)","Turkish(tr)","Simplified Chinese(zh)","Traditional Chinese (zh-tw)"];

	},
	//
	//
	//
	_getLocalizedString: function(key,locale){
		//
		//summary: 
		//
		console.debug("Key:"+key + " Locale:'"+locale+"'");
		var localizedString=this.localizedStrings[key][locale];
         console.debug("Value: "+localizedString);
		return localizedString;
	},
	//
	//
	_getSupportedLocales: function(){
		//
		// Returns the list of supported Locales
		//
		var licenseSpecSupportedLocales="en,cs,de,el,es,fr,it,ja,ko,lt,pl,pt,ru,sl,tr,zh_TW,zh,in";
		var itemL=licenseSpecSupportedLocales.split(",");
		for(var uu=0; uu<itemL.length;uu++){
		 var langCandidate=dojo.trim(itemL[uu].replace("_","-"));
		  console.debug(" Compare supported locale: "+langCandidate + " to current locale (dojo.locale): "+dojo.locale);
		  if(this._matchingLocale(langCandidate)){
			  this.supportedLocale=langCandidate; // returns one of the locale specified.
			  console.debug("Match found. ");
			  break;
		  }
		}
		console.debug(" Match="+this.supportedLocale);
		return this.supportedLocale;
	},
	//
	//Checks to see if the current locale on this browser 
	//is supported by this product.
	//If the current locale is not supported, will return false (English locale will be used)
	//fr will match fr_FR, fr
	//User can only specify one of the followings:
	//en, fr, de, it, 
	_matchingLocale: function(candidate){
		//
		//Summary:
		//
		
		var currentLocale=dojo.locale; //Could have length of 2 or a length of 5 (fr, fr_FR)
		var lowerCaseLocale=currentLocale.toLowerCase(); //Convert to lower case to ease comparison
		
		//candidate can only be one of the supported locales: 2 characters, except zh-cn, zh-tw and pt-BR
		var candidateLowerCase=dojo.trim(candidate.toLowerCase()); //Make sure to trim possible spaces
		
		//Print to validate
		console.debug("Current Locale: "+lowerCaseLocale + " candidate in lower case: " + candidateLowerCase);
		
		//Length of the selected locale.
		var localeLength=lowerCaseLocale.length;
				
		//Only language was specified (fr, de, it, ...)
		if(localeLength==2){ //Only the language was specified.
			return (lowerCaseLocale==candidateLowerCase);
		}else if(localeLength==5){ //5 characters
			if(lowerCaseLocale=="zh-tw" ){ // In this case, the match has to be perfect
				if(lowerCaseLocale==candidateLowerCase) {
					return true;
				} else
					return false;
			}else { // Only select the first two characters and compare them to the supported ones
				var langLocale=lowerCaseLocale.substring(0,2);
				return (langLocale==candidateLowerCase);
			}
		}
		//Any other case
		return false;
	},
	//
	// 
	//
	_getLocale:function(){
		//
		// Summary: Calculates the proper locale
		//
		var matchingLocale=this._getSupportedLocales();
		//Line below is required, because the locale in dojo (zh-TW) doesn't match file extension _zh_TW
		if(matchingLocale=="zh-tw" || matchingLocale=="zh-TW" ) matchingLocale="zh_TW"; 		
		console.debug("Matching Locale: "+matchingLocale);
		
		return matchingLocale;
	},
	
    _licenseRejected: function() {
	  // summary:
	  //     This method is called, when the user rejects the License.
      //
	console.debug("The license wasn't accepted.");
	//publish an event that the License has been rejected.
}});