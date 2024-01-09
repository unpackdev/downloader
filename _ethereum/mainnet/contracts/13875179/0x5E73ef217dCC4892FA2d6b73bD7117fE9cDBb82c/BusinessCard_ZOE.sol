//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC1155.sol";

//   ___  _  _  ___ __      __   _   __      __   _       _     _   _ __   __
//  / __|| || ||_ _|\ \    / /  /_\  \ \    / /  /_\     | |   | | | |\ \ / /
// | (__ | __ | | |  \ \/\/ /  / _ \  \ \/\/ /  / _ \    | |__ | |_| | \ V /
//  \___||_||_||___|  \_/\_/  /_/ \_\  \_/\_/  /_/ \_\   |____| \___/   \_/

//                        /dyh+                                  
//                        m+ `od:                                
//                        N:  .+yy.                              
//                        N:   .+:h+                             
//                        m:    /-`oy. ````                      
//                        ss ``  o-`:yosoosso/-`                 
//                        `d+`/:.o-  ``    `.:oy+`               
//                         sd. +:.`..`         `+h://::///////:. 
//                         -ds/:.-yhs-    /`     ./://+oooo+/:+yy
//                           -yd`hMNNs .  /   `-`  `o--.`     .yy
//                            sy oyhho/-   . :ss+: s`       -sy: 
//                           .N- .`--`     -yMMmM-`s-    `:yy-   
//                           sN `//` :mNys` -yhh+/:/``ohos/`     
//                          .Mo/+o+  -MMMm. . :./Nshyy+`         
//                          -M-o+++/o+dNy  ./-  hy               
//                        `oh:s   `.-+/:+oo+/.-yh`               
//                      `+d+` s      -:. ```--:N-                
//                    -osh-   s             `:m+                 
//                  .sy:-/    o    ..       `do                  
//                 /h/` o`    .:    ::     .sN`                  
//                /d.  +.      .     -`    :/m+                  
//               `N:   o                    `+m                  
//               :N   `+                     :M                  
//               /N    o                     /m                  
//               -M`   +                     do                  
//                m/   +     .-:`      -:. .yh  `/.              
//                hh  --        -.    `  . `M. +dmo              
//               oh`+`+     .-`      `/:-   m/+d`oh              
//              .N.  /y    `+       ://`   `M+N- +m              
//              sh    s`   ::     ./- ./   -Mm/  yy              
//              +m    -/   o`    :-`   o   .h.  :N.              
//              .M.   `o   o     `  .-`::   s  /d:               
//              `yd:../+  ./       ./dd/y   s:sy-                
//             -hy+:-/M.  `hs+:-ossyymMs+:  /N/                  
//             md-o:+oy   `N/-/+:..  .myoy`  /h:`                
//             -syyhNy`   sh          `-:sh`  .yss+-`            
//                od:    -N-              sh:    :/hdo           
//               +Mo:`/.`do                :hyssosmymd`          
//               -mmyydyy/                     ...` `            


contract BusinessCard_ZOE is ERC1155{

	// Variables
	// ------------------------------------------------------------------------
	string private _name = "ZOE";
	string private _symbol = "ZOE";
	string public Team = "pupupupuisland";
	string public Job_Title = "Game Designer";
	string public Email = "pupupupuisland@gmail.com";
	string public Twitter = "@pupupupuisland";
	string public Personal_Twitter = "@Zoeyeeyeeyee";
	string public Design_by = "pupupupuisland";
	string public SFX_Design = "ZOE";
	address owner_1 = 0x3A58B3F526AdC0222D2a081C96C744b9bB822685;
	address owner_2 = 0x3045588E18af3C1D614D20564D2614Cd65C51238;

	// Constructor
	// ------------------------------------------------------------------------
	constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmSjBpN51HgQUepdUgdBddmZAVtj4WdCP6NtKhEDH1cRQp"){
		_mint(owner_2, 1, 300, "");
	}

	function name() public view virtual returns (string memory) {
		return _name;
	}

	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	// Modifiers
	// ------------------------------------------------------------------------
	modifier owner() {
		require(msg.sender == owner_1 || msg.sender == owner_2, "CALLER_IS_NOT_OWNER");
		_;
	}

	// Mint functions
	// ------------------------------------------------------------------------
	function mint(address to, uint256 id, uint256 quantity) external owner {
		_mint(to, id, quantity, "");
	}

	// Burn functions
	// ------------------------------------------------------------------------
	function burn(address to, uint256 id, uint256 quantity) external owner {
		_burn(to, id, quantity);
	}

	// setting functions
	// ------------------------------------------------------------------------
	function setBaseURI(string memory baseURI) public owner {
		_setURI(baseURI);
	}

	function setName(string memory newName) public owner {
		_name = newName;
	}

	function setTeam(string memory newTeam) public owner {
		Team = newTeam;
	}  

	function setJob_Title(string memory newJob_Title) public owner {
		Job_Title = newJob_Title;
	}  

	function setTwitter(string memory newTwitter) public owner {
		Twitter = newTwitter;
	}  
	
	function setEmail(string memory newEmail) public owner {
		Email = newEmail;
	}

	function setPersonal_Twitter(string memory newPersonal_Twitter) public owner {
		Personal_Twitter = newPersonal_Twitter;
	}  

	function setDesign_by(string memory newDesign_by) public owner {
		Design_by = newDesign_by;
	}  

	function setSFX_Design(string memory newSFX_Design) public owner {
		SFX_Design = newSFX_Design;
	}    
}
