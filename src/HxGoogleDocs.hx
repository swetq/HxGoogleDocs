package ;

import haxe.Http;

/**
 * ...
 * @author Jonas Nyström
 */

 using StringTools;

class HxGoogleSpreadsheet {
	private var key:String;
	private var authToken:String;
	private var worksheetLinks:WorksheetLinks;
	private var xmlCellFeed:Xml;
	
	public function new(email:String, passwd:String, key:String) {
		this.key = key;		
		this.authToken = getAuthToken(email, passwd);
		this.worksheetLinks = getWorksheetLinks(this.authToken, this.key);
		this.xmlCellFeed = getCellFeed(this.authToken, this.worksheetLinks.cellLink);
	}
	
	private static var urlClientLogin = 'https://www.google.com/accounts/ClientLogin';
	
	private function getAuthToken(email:String, password:String, ?service:String = 'wise'): String {
		var authToken = '';
		var http = new Http(urlClientLogin);
		http.setParameter('Email', email);
		http.setParameter('Passwd', password);
		http.setParameter('accountType', 'HOSTED_OR_GOOGLE');
		http.setParameter('source', 'service test');
		http.setParameter('service', service);		
		http.onError = function(msg:String) { trace(msg); }
		http.onData = function (data:String) {
			var a = data.split('Auth=');		
			authToken = a.pop();						
		}
		http.request(false);
		return authToken;
	}
	
	private function getAuthorizedHttp(authToken:String, url:String): Http {
		var http = new Http(url);
		var tokenHeader = 'GoogleLogin Auth=' + authToken;
		http.setHeader('Authorization', tokenHeader);
		return http;
	}
	
	private function getWorksheetLinks(authToken:String, key:String): WorksheetLinks {
		var urlWorksheet = 'https://spreadsheets.google.com/feeds/worksheets/KEY/private/full'.replace('KEY', key);
		var worksheetLinks:WorksheetLinks = {
			listLink:null,
			cellLink:null,
		}
		var http = getAuthorizedHttp(authToken, urlWorksheet);
		http.onError = function(msg:String) { trace(msg); }
		http.onData = function(data:String) { 
			var xmlFeed = Xml.parse(data).firstElement();
			var xmlFirstEntry = Iterators.first(xmlFeed.elementsNamed('entry'));
			var xmlEntryLinks = Iterators.array(xmlFirstEntry.elementsNamed('link'));
			worksheetLinks.listLink =  xmlEntryLinks[0].get('href');
			worksheetLinks.cellLink =  xmlEntryLinks[1].get('href');
		};
		http.request(false);	
		return worksheetLinks;
	}
	
	private function getCellFeed(authToken:String, cellLink:String): Xml {
		var xmlCellFeed:Xml = null;
		var http = getAuthorizedHttp(authToken, cellLink);
		http.onError = function(msg:String) { trace(msg); }
		http.onData = function(data:String) { 
			xmlCellFeed = Xml.parse(data).firstElement();
		};
		http.request(false);			
		return xmlCellFeed;		
	}	
	
	private function getWorksheetCells(xmlCellFeed:Xml): WorksheetCells {
		var cells = new WorksheetCells();
		var xmlEntries = Iterators.array(xmlCellFeed.elementsNamed('entry'));
		for (entry in xmlEntries) {
			var cell = Iterators.first(entry.elementsNamed('gs:cell'));
			var text = cell.get('inputValue');
			var row = Std.parseInt(cell.get('row'))-1;
			var col = Std.parseInt(cell.get('col'))-1;
			
			if (cells[row] == null) cells[row] = new Array<String>();
			cells[row][col] = text;
		};
		return cells;		
	}	
	
	private function getWorksheetSize(xmlCellFeed:Xml):WorksheetSize {
		var r:WorksheetSize = {
			rows: Std.parseInt(Iterators.first(xmlCellFeed.elementsNamed('gs:rowCount')).firstChild().toString()),
			cols: Std.parseInt(Iterators.first(xmlCellFeed.elementsNamed('gs:colCount')).firstChild().toString()),
		}
		return r;
	}
	
	//-----------------------------------------------------------------
	
	public function getCells(): WorksheetCells {
		return getWorksheetCells(this.xmlCellFeed);
	}
	
	public function getSize():WorksheetSize {
		return getWorksheetSize(this.xmlCellFeed);
	}
	
}

typedef WorksheetLinks = {
	listLink:String,
	cellLink:String,
}

typedef WorksheetCells = Array<Array<String>>;

typedef WorksheetSize = {
	rows:Int,
	cols:Int,
}