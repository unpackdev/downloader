// SPDX-License-Identifier: MIT

/*                                                
 ``..........................................................................`` 
`..............................................................................`
................................................................................
................................................................................
................................................................................
................................................................................
................................................................................
.........................................................oho....................
................./ss/.................................../NyNo...................
................omsyN:..................................oN+hN...................
................mh//my..................................sN/oN/..................
...............:Ns//hm.......-:/+osssyyyyyysso+/::-.....ym//Ns..................
...............+N+//yN...-/syhhyysooooooooooossyhhhhyo:-yN//hd..................
...............oN+//sN:oyhhso+/osso+///////////+syyysyhhmN//sN-.................
...............ym///yNdyo/////ym++ymo//////////hm::oms/+yN+/+N+.................
...............hm///ym////////hm:``dd//////////ym+.-dd//sN+//hh-................
...............hd///+o/////////sdhddo///////////oyhhy++/+m+//+dd:...............
...............mh///////////////+yhhhs+///////////+ydddy+//////yN+..............
..............-Ny///////////////yN-`-dd///////////sN: .yN+//////sN/.............
..............oN+///////////////+mh+/hm///////////+hmo+hm+///////dd.............
..............ym//////////////////oyys//////////////+sso/////////oN/............
..............sm//////////////////sdhdds////////////+yddhs+///////Ns............
..............:Ns////////////////+Ns  :Ns///////////yN.`-dd//////+N+............
...............+No////////////////smhoymo///////////+mh+/hm//////yN-............
................+my+///////////////+ooo+/////////////+oyys+/////oNo.............
.................-ydo//////////////////////+++++///////////////ymo..............
.................../hdo////////////////////hddddh+///////////odh:...............
.................-/sdmmds+//////////////////+++++/////////+sdh+.................
.............../ydhs++oydmdyo+////////////////////////+oshmm/...................
.............-yds+//////++oydddhysoooooo++++ooooossyhhhhyoodd/..................
............/mh+/////////////+osyhhdddddddddhhhhhhyso++////+sms.................
.........../my///////////////////////+++++///////////////////omy................
..........:mh/////////////////////////////////////////////////+my...............
..........dd+//////////////////////////////////////////////////sN:..............
.........oN+//////////++//////////////////////////////////sy////my..............
........-Ny//////////+mo//////////////////////////////////yN+///yN-.............
........ym+//////////dm///////////////////////////////////oNo///+No.............
......./Ns//////////oNo///////////////////////////////////+Ns////dd.............
.......dd///////////dm/////////////////////////////////////Nh////yN-............
`.....+No//////////oNs/////////////////////////////////////dm////oN+...........`
 ``...mh///////////dm//////////////////////////////////////yN/////my.........``      
*/

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721.sol";
 
contract ALIENPHRENS is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant ALIENPHRENS_MAX = 10000;

    uint256 public totalSupply = 0;


    string public baseUri = "https://alienphrens.com/api/metadata?id=";

    constructor() ERC721("ALIENPHRENS", "ALIENPHRENS") {}

    function dynamic_cost(uint256 _supply) internal pure returns (uint256 _cost){
        //Tiered pricing

        //TODO need to add 1 to make it work (1001, etc)
        if(_supply<1001){ //i.e. 1001 or 2001
            return 0.03 ether;
        }
        else if(_supply<2001){
            return 0.04 ether;
        }
        else if(_supply<3001){
            return 0.05 ether;
        }else{
            return 0.069 ether;
        }
    }


    // PUBLIC FUNCTIONS
    function mint(uint256 _numberOfTokens) external payable {
        
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numberOfTokens <= ALIENPHRENS_MAX, "Purchase would exceed ALIENPHRENS_MAX");

        if(_numberOfTokens>1){
            uint256 cumulative_cost = 0;
            for (uint256 n = 1; n <= _numberOfTokens; n++) {
                cumulative_cost += dynamic_cost(curTotalSupply+n);
            }
            require(cumulative_cost <= msg.value, "ETH amount is not sufficient");
        }else{
            require(dynamic_cost(curTotalSupply+1) <= msg.value, "ETH amount is not sufficient");
        }
        
        
        for (uint256 i = 1; i <= _numberOfTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }

        totalSupply += _numberOfTokens;
    }

    // OWNER ONLY FUNCTIONS
    /* function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    } */

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance;
        (bool transferOne, ) = payable(0x8f5f10F0cDF3457b2E6C132fBC4d59E6B982de8A).call{value: balanceOne}(""); 
        require(transferOne, "Transfer failed.");
    }

    // INTERNAL FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}