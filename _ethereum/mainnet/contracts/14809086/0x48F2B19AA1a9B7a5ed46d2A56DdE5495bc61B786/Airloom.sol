pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title Airloom
 * A first breath, a genisis project.
 * This publicly distributed image is how I sign and "formalize" my agreements, cute.
 */

/* 


                                                                          .:::::::.:::::. 
                                            --                       ..:::.             .:
                                           --                    .:::                    -
                                         :-:                  :::.                       -
                                       .:.:                :::                           -
                                     .:..:              .::                             :.
                                    :. .:            .::                               -. 
                                  ::  .:           ::.                               ::   
                                ::   .:          ::                               .::     
                              ::    .:         ::                             .:::        
               ::.          ::     .-        :.                         :::::.            
           :::.   ::      ::      ::    :..--              ........::::.                  
         ::         :.  ::       .:       - .......:::::..                                
       ::            =:.        .:      .-                                                
      -.           :: -        .-      .-                                                 
     -.         ::.   -       .-       =                                                  
:   .:      .::.      :.     .:  .    .:               ....                               
 -:.=  ..:::          .:     :.:+      -                 :.                               
    +:.               .:   .=: :.  :   ::              ::                                 
    -.                .::::=   -::.      :.        :::.                                   
     -.            ...--  -                ........                                       
       ::.::::::::.   :. -                                                                
                      - -                                                                 
                      --                                                                  
                      =.                                                                  
                     .=                                                                   
                     =:                                                                   
                    --                                                                    
                   ::-   

        
                 
*/

contract Airloom is ERC721, Ownable {

	string public baseURI;
	uint256 public constant MAX_SUPPLY = 1;
	uint256 public mintedSoFar;
	address public store;

	constructor( string memory __name, string memory __symbol, string memory __baseURI ) ERC721(__name, __symbol) {
		baseURI = __baseURI;
	}

	modifier onlyOwnerOrStore() {
		require(store == msg.sender || owner() == msg.sender,"!!! you need to point your nftmint at your store !!!");
		_;
	}

/*	function setBaseURI(string memory __baseURI) external onlyOwner {
		baseURI = __baseURI;
	}*/

	function _baseURI() internal view virtual override returns (string memory) {
		return "data:application/json;base64,eyJuYW1lIjogIlNpZ25hdHVyZSIsICJkZXNjcmlwdGlvbiI6ICIuZGVzY3JpcHRpb24uIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0F5TXpjdU1ESWdNVFUxTGpRMklqNDhaR1ZtY3o0OGMzUjViR1UrTG1Oc2N5MHhMQzVqYkhNdE1udG1hV3hzT201dmJtVTdjM1J5YjJ0bExXMXBkR1Z5YkdsdGFYUTZNVEE3ZlM1amJITXRNWHR6ZEhKdmEyVTZJekF3TURBd01EdDlMbU5zY3kweWUzTjBjbTlyWlRvak1EQXdNREF3TzMwOEwzTjBlV3hsUGp3dlpHVm1jejQ4ZEdsMGJHVStVMmxuYm1GMGRYSmxQQzkwYVhSc1pUNDhaeUJwWkQwaVFTSWdaR0YwWVMxdVlXMWxQU0pCSWo0OGNHRjBhQ0JqYkdGemN6MGlZMnh6TFRFaUlHUTlJazAxTmprdU5TdzNOemd1TldNeE5pNDVNU3d6TWk0ekxEZzNMamcxTFRNNExERXlNQzA0TWkweE9Td3pOaTAzTnl3eE5URXROamdzTVRVd0xETXVPQzB4TGpjMExEa3RNak1zT0MwMk9DMHpMall0TXpRdU5qZ3RNakV0TkRBdE5ESXRNVE10Tnk0NE55d3hOUzA0TGpZNUxESTJMall5TFRNc016VXNNVEVzTVRJc05ESXVNak1zTXk0MExEY3lMVEl3TFRNdU5Ea3NOaTQwTkMwMUxqa3NNVEV1TmpRdE5Td3hNeXd5TERNc09TNDBOUzB1T0Rnc01URXROV2d5SWlCbWFXeHNMVzl3WVdOcGRIazlJakFpSUhSeVlXNXpabTl5YlQwaWRISmhibk5zWVhSbEtDMDFOamt1TURZZ0xUWTVNUzQxTlNraUlDOCtQSEJoZEdnZ1kyeGhjM005SW1Oc2N5MHlJaUJrUFNKTk5qZzVMalVzTmprMUxqVWlJSFJ5WVc1elptOXliVDBpZEhKaGJuTnNZWFJsS0MwMU5qa3VNRFlnTFRZNU1TNDFOU2tpTHo0OGNHRjBhQ0JqYkdGemN6MGlZMnh6TFRFaUlHUTlJazAyTkRjdU5TdzRNall1TlNJZ2RISmhibk5tYjNKdFBTSjBjbUZ1YzJ4aGRHVW9MVFUyT1M0d05pQXROamt4TGpVMUtTSXZQand2Wno0OFp5QnBaRDBpVENJZ1pHRjBZUzF1WVcxbFBTSk1JajQ4Y0dGMGFDQmpiR0Z6Y3owaVkyeHpMVEVpSUdROUlrMDJOelV1TlN3M05EZ3VOV010TXk0ek9Td3pMamt5TERFeExqTXlMRGd1TXpnc016UXNOeXcxTWk0d09DMHlMamswTERrMUxqTXhMVEUwTGpNMUxEazJMVFEzTERJdE1qVXRNelF1TlRFdE1Ua3VOUzAzTWl3ekxUVTBMRE0wTGpBMkxUY3lMamswTERZM0xqUTRMVFUyTERneUxERTBMamd4TERFMExqVTJMRFExTGpNeExUVXVNRFlzTkRVdE1UTXNNQzB6TFRNdU5qa3RNaTA0TFRJaUlDQm1hV3hzTFc5d1lXTnBkSGs5SWpBaUlIUnlZVzV6Wm05eWJUMGlkSEpoYm5Oc1lYUmxLQzAxTmprdU1EWWdMVFk1TVM0MU5Ta2lMejQ4Y0dGMGFDQmpiR0Z6Y3owaVkyeHpMVEVpSUdROUlrMDNNamN1TlN3M056QXVOU0lnZEhKaGJuTm1iM0p0UFNKMGNtRnVjMnhoZEdVb0xUVTJPUzR3TmlBdE5qa3hMalUxS1NJdlBqeHdZWFJvSUdOc1lYTnpQU0pqYkhNdE1TSWdaRDBpVFRjeU55NDFMRGM0T1M0MUlpQjBjbUZ1YzJadmNtMDlJblJ5WVc1emJHRjBaU2d0TlRZNUxqQTJJQzAyT1RFdU5UVXBJaTgrUEhCaGRHZ2dZMnhoYzNNOUltTnNjeTB4SWlCa1BTSk5Oamt5TGpVc056YzVMalUzWXkwdU5EVXRMamMwTFM0NE5DMHhMakkzTFRFdE1TSWdkSEpoYm5ObWIzSnRQU0owY21GdWMyeGhkR1VvTFRVMk9TNHdOaUF0TmpreExqVTFLU0l2UGp3dlp6NDhMM04yWno0PSJ9";
	}

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
    }

	function setStore(address _store) external onlyOwner {
		store = _store;
	}

	function mint(address to) public onlyOwnerOrStore {
		require(mintedSoFar < MAX_SUPPLY, "Exceeds max supply");
		_mint(to, mintedSoFar);
		mintedSoFar += 1;
	}
}