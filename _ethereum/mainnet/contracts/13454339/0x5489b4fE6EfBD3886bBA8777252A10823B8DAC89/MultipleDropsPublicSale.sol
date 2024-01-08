// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// thedrops.xyz
//                     ........                                                                                         
//                   ..'..........              .                                                                      
//                 ..'....'........          ....                                                                      
//              ...''...,:;'.::.....       ..'..                                                                       
//              ..,:,'',:,.';:'...,,..    ....                                                                         
//               .,'....',''','''',;.     ...                                                                          
//               .,. ............ .'.       .......     .,;;;;;;;;;,..;;'.  ..;;'...;;;;;;;'.                          
//              .''..'..'..,..,.  .''.      .......     ;OXXXNNNNXXO,:KWx.  .lXNo..dNNXXXXXx'                          
//              .,. .,,.,'.,,',.   .,.                  .',;:kWWk;,'.:XMk'...oNWd..xWNd;;;;'.                          
//             .''.  .''.....'..   .''.      .....         ..dWWo.  .:XMXOkkkKWWd..xWW0xxxd;.                          
//            .''....................'..      ....         ..dWWo.   :XMXkxxxKWWd..xWW0xxxd,.                          
//          ..'''''................'''''.                  ..dWWo.  .:XMk.  .lNWd..xWNd;;;;'.                          
//         .',..,.                 .,'..'..                ..oXXl.   :KNx.  .lXNo..dNNXXXXXx'                          
//  ...   .',..',.                 .,'. .'.                ...,,..   .,,..   .,,....,,,,,,,'.                          
//  ....  .,.  ',.                 .,'  ...              .:lllllc;'.  .,llllllc;..  .':lool:'.  .:llllll:'. .'coool:'. 
//    ..  .''. .,,..             ..',.  .'.              ;KMMWXKXNKx,..oWWXKKXNNk,.'dXNX00KNXx,.,0MWXKKXWXl,oXWXO0XNKl.
// ....... ..'....'''''.......'''''.. .....              ;KMM0;.'lKWO,.dWNd,,:OMNc'kWNx,..'oXMO,,0MKl,,oXMOl0MNk:,:odc.
// .......   .......'.....................               ;KMMO'  .dWNl.oWMNK0XWNx':XM0,    .kMNc,0MWXKKXNKc.:x0XXK0kd;.
//        ..    .....,,'................                 ;KMMO'  'kMXc.oWWOldXM0;.;0MK:.   ,0MX:,0MXdlll:'..;::;;cdXMXl
//      ..'.      ..''...........''..                    ;KMMXdld0WXo..oWNl..lNWx..lXWKdcco0WNo.,0M0,     .;0WXxlcdKMNl
//    ..'..      .''..           .....                   ,kKKKKK0ko;. .c0O:. .o0O:..,oOKKXKOd;. 'xKx'      .,oO0KKK0x:.
//   ....      ..,'..             ..'..                  .........     ....   .....  ...''...   .....        ....'...  
//   ..        .;;;'.             .';,'.                    .                                                          
//             ..,;.      ...      .,'..                                                                               
//              .',.  ...........  ...                                                                                 
//              .',.......   ..''.....                                                                                 
//               .'.....       .......                                                                                 
//                 .              .                                                                                    

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC165.sol";
import "./ERC1155.sol";

/* solhint-enable */

// The Drops Multiple Public Sale
contract MultipleDropsPublicSale is Ownable, IERC165 {
    using Address for address;
    using SafeMath for uint256;

    address public nftContractAddress;

    mapping(address => bool) private _admins;
    mapping(address => uint256) private _buyers;
    bool private buyerLimited;

    uint256 public currentTokenIndex;
    uint256[] public _availableTokens;

    event AdminAccessSet(address _admin, bool _enabled);
    event NftTransfered(uint256 _nftId, address _buyer, uint256 _timestamp);
    event NftStartTransfer(uint256 _nftId, uint256 _randomIndex, address _buyer, uint256 _timestamp);

    constructor(address _nftContractAddress) {
        require(
            _nftContractAddress.isContract(),
            "_nftContractAddress must be a NFT contract"
        );
        nftContractAddress = _nftContractAddress;
        _admins[msg.sender] = true;
        buyerLimited = true;
        currentTokenIndex = 0;
    }

    // Transaction Functions
    /**
     * Default Interfaces for accepting ETH
     */
    receive() external payable {
        deposit();
    }
    fallback() external payable {
        deposit();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return false;
    }

    /**
     * Withrawal Function for Admins
     */
    function withdrawalAll() external onlyAdmin() {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * take eth and distribute NFT
     */
    function deposit() public payable {
        require((msg.value == 0.25 ether || msg.value == 0.5 ether || msg.value == 0.75 ether), "Please transfer 0.25, 0.5 or 0.75 ether");
        uint256 amount = msg.value / 0.25 ether;
        require(
            (_buyers[msg.sender] + amount < 4 && buyerLimited == true) || (!buyerLimited),
            "Only 3 purchases per wallet allowed"
        );
        require(
            (_availableTokens.length - currentTokenIndex) >= amount,
            "Currently no NFT available. Please try again later"
        );
        // ugly but less gas usage
        transferNft(_availableTokens[currentTokenIndex], msg.sender);
        _buyers[msg.sender] = _buyers[msg.sender] + 1;
        currentTokenIndex++;

        if (amount > 1) {
            transferNft(_availableTokens[currentTokenIndex], msg.sender);
            _buyers[msg.sender] = _buyers[msg.sender] + 1;
            currentTokenIndex++;
        }
        if (amount > 2) {
            transferNft(_availableTokens[currentTokenIndex], msg.sender);
            _buyers[msg.sender] = _buyers[msg.sender] + 1;
            currentTokenIndex++;
        }
    }

    /**

     *
     * @param to - address of the artwork recipient
     */
    function transferNft(uint256 nftId, address to) private {
        require(
            ERC1155(nftContractAddress).balanceOf(owner(), nftId) > 0,
            "This Token is sold out."
        );
        ERC1155(nftContractAddress).safeTransferFrom(
            owner(),
            to,
            nftId,
            1,
            '0x0'
        );
        emit NftTransfered(nftId, to, block.timestamp);
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getNftsLeft() public view returns (uint256) {
        return _availableTokens.length - currentTokenIndex;
    }

    function getCurrentTokenIndex() public view returns (uint256) {
        return currentTokenIndex;
    }

    function purchasedAmountByWallet(address wallet) public view returns (uint256) {
       return _buyers[wallet];
    }

    function setBuyerLimited(bool enabled) external onlyOwner {
        buyerLimited = enabled;
    }


    function addNftIds(uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _availableTokens.push(_ids[i]);
        }
    }

    function resetNftIds(uint256[] memory _ids) external onlyOwner {
        delete _availableTokens;
        currentTokenIndex = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            _availableTokens.push(_ids[i]);
        }
    }

    // Admin Functions
    /**
     * Set Admin Access
     *
     * @param admin - Address of Minter
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[msg.sender] || msg.sender == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}
