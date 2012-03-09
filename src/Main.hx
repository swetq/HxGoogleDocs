package ;

import neko.Lib;

/**
 * ...
 * @author Jonas Nyström
 */

class Main {	
	static var email = 'jonasnys';
	static var passwd = '%gloria!';
	static var keyTestSheet = '0Ar0dMoySp13UdE93Vno1QlJ3cklrLW5zTWItOTRZS2c';
	
	static function main() {
		var gs = new HxGoogleDocs.HxGoogleSpreadsheet(email, passwd, keyTestSheet);
		trace(gs.getSize());
		trace(gs.getCells());
	}		
}