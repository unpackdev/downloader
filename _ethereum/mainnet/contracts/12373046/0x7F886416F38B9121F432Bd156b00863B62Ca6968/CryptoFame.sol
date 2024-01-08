/*                                                                                                                                             
                                                                                                              *                                       
                                                                                                           ##                                         
                                                                                                      (####(                                          
                                                                                               ##########,                                            
                                                  (####################################################                                               
                                         ###########################################################                    ####,                         
                                    ##############,           .################################/                    ##########                        
                                ,########                           *                                            .####     ###                        
                              #######                   ..    (###                                   ######/    ####     ,##                          
                            #####              ######      ####/                             ###  .########   (####   ###    ,##                      
                          /####             ######       #####                          (########## ######   ######        ## #                       
                         ###(             ######       #####      #               ###############   #####   ########    #### ##                       
                        ###             ######       *#####.#####         (###   ######   #####    #####   ##############   #/                        
                        ##             #####.      ###########    *##########   #####,   #####    #####  ##.  /######     ##                          
                       ##.            #####    ###########     #####..######   #####    #####    #########             *##                            
                       (##           #####   ###########    #####     .####  .#####    #####     ######             ####                              
                        ##         .####   ###  *######    ####       ###   (#####    #####                    (#####                                 
                          ##.    ####     #.   #######    ####       ###   ######    #####               /#######                                     
                                         ,    #######    ####      (#### *######                  #########/                                          
                                             #######    ######   /##########,           (###########.                                                 
                                            ######*     ########### ###        ##############                                                         
                                           ######       ,#######         #############                                                                
                                         ,######                   .############(                                                                     
                                        #######                #############                                                                          
                                       ######(              ############                                                                              
                                      ######            .############                                                                                 
                         #          ######,           #############                                                                                   
                        #.        #######          ##############                                                                                     
                        ##     /######(          ##############                                                                                       
                        (###########           #######                                                                                                
                                             *                                                                                                        
*/

/* 

The CryptoFame page is a grid divided in 72 * 40 = 2880 bricks.
Users can acquire rectangular groups of bricks by minting or buying an ERC721 token.
Ownership of a token gives the right to display metadata (logo and url) on the corresponding bricks.
Anyone can come and buy (steal) a token from a user by paying twice the previous price.
Half of the difference in price goes to the previous owner.
So if you pay 1 ETH for a group of bricks and someone steals it, you get 1.5 ETH back.
Game on!

*/

pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract CryptoFame is Ownable, ERC721 {
    using SafeMath for uint256;

    // Dev fee (%) and address
    uint256 private constant DEV_FEE = 10;
    address private constant DEV_ADDR =
        0x2320F4CBb1a8aAC41cf4A488623A8b3bd31b5D6D;

    // The ETH price of a brick (0.05 ETH)
    uint256 private constant UNIT_VALUE = 50000000000000000;

    // The minimum fee (%) when buying an existing token
    uint256 private constant MINIMUM_FEE = 100;

    // The owner cut (%) when buying an existing token
    uint256 private constant OWNER_CUT = 50;

    // The maximum zone area that can be minted
    uint256 private constant MAX_AREA = 50;

    struct Zone {
        uint72 start;
        uint8 width;
        uint8 height;
    }

    // Mapping between tokens and zones
    mapping(uint256 => Zone) private zones;

    // Mapping between tokens and prices
    mapping(uint256 => uint256) private values;

    // bitmap reresentation of the grid
    uint72[40] private grid;

    event ZoneUpdate(
        uint256 tokenId,
        uint256 start,
        uint8 width,
        uint8 height,
        uint256 value,
        string ipfsHash
    );
    event Withdrawened(uint256 balance);

    constructor() ERC721("CryptoFame", "CTF") {
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    function mint(
        uint72 _start,
        uint8 _width,
        uint8 _height,
        string calldata _ipfsHash
    ) external payable returns (uint256 tokenId) {
        Zone memory zone = Zone(_start, _width, _height);
        require(_area(zone) >= 0, "CTF: area is empty");
        require(_area(zone) <= MAX_AREA, "CTF: area is too big");

        tokenId = totalSupply().add(1);

        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _ipfsHash);
        _setTokenZone(tokenId, zone);
        _setTokenValue(tokenId, msg.value);

        emit ZoneUpdate(tokenId, _start, _width, _height, msg.value, _ipfsHash);
    }

    function buy(uint256 _tokenId, string calldata _newIpfsHash)
        external
        payable
    {
        require(_exists(_tokenId), "CTF: buying nonexistent token");

        address tokenOwner = ownerOf(_tokenId);
        uint256 tokenValue = values[_tokenId];

        _safeTransfer(tokenOwner, _msgSender(), _tokenId, "");
        _setTokenValue(_tokenId, msg.value);
        _setTokenURI(_tokenId, _newIpfsHash);

        uint256 ownerCut = (msg.value.sub(tokenValue)).mul(OWNER_CUT).div(100);
        payable(tokenOwner).transfer(tokenValue.add(ownerCut));

        Zone memory zone = zones[_tokenId];

        emit ZoneUpdate(
            _tokenId,
            zone.start,
            zone.width,
            zone.height,
            msg.value,
            _newIpfsHash
        );
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        uint256 devFee = balance.mul(DEV_FEE).div(100);
        payable(DEV_ADDR).transfer(devFee);
        payable(owner()).transfer(balance.sub(devFee));

        emit Withdrawened(balance);
    }

    function zone(uint256 _tokenId)
        external
        view
        returns (
            uint256 start,
            uint256 width,
            uint256 height
        )
    {
        Zone memory zone = zones[_tokenId];
        start = zone.start;
        width = zone.width;
        height = zone.height;
    }

    function value(uint256 _tokenId) external view returns (uint256 val) {
        val = values[_tokenId];
    }

    function _setTokenValue(uint256 _tokenId, uint256 _value) internal {
        uint256 currentValue = values[_tokenId];
        if (currentValue == 0) {
            Zone memory zone = zones[_tokenId];
            require(
                _value >= _area(zone).mul(UNIT_VALUE),
                "CTF: value is too low"
            );
        } else {
            require(
                _value >= currentValue.mul(100 + MINIMUM_FEE).div(100),
                "CTF: value is too low"
            );
        }
        values[_tokenId] = _value;
    }

    function _setTokenZone(uint256 _tokenId, Zone memory _zone) internal {
        uint72 startX = _zone.start % 72;
        uint72 startY = _zone.start / 72;

        for (uint72 i = startY; i < startY + _zone.height; i++) {
            uint72 row = grid[i];
            for (uint72 j = startX; j < startX + _zone.width; j++) {
                uint72 map = (uint72(1) << j);
                require(row & map == 0, "CTF: zone overlap");
                row = row | map;
            }
            grid[i] = row;
        }
        zones[_tokenId] = _zone;
    }

    function _area(Zone memory _zone) internal pure returns (uint256) {
        return uint256(_zone.width).mul(_zone.height);
    }
}
