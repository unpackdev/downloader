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
import "./IERC1155Receiver.sol";

/* solhint-enable */

// The Drops Multiple Public Sale
contract MultipleDropsSale is Ownable, IERC1155Receiver {
    using Address for address;
    using SafeMath for uint256;

    address public nftContractAddress;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _buyers;
    mapping(address => bool) private _whitelisted;

    struct AvailableToken {
        uint256 id; // short id (up to 32 bytes)
        uint256 amount; // number of available tokens
    }

    AvailableToken[] public _availableTokens;

    event AdminAccessSet(address _admin, bool _enabled);
    event NftTransfered(uint256 _nftId, address _buyer, uint256 _timestamp);
    event AddedMultipleToWhitelist(address[] account);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor(address _nftContractAddress) {
        require(
            _nftContractAddress.isContract(),
            "_nftContractAddress must be a NFT contract"
        );
        nftContractAddress = _nftContractAddress;
        _admins[msg.sender] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return false;
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

    /**
     * Withrawal Function for Admins
     */
    function withdrawalAll() external onlyAdmin() {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * Withrawal NFTs Function for Admins
     */
    function withdrawalAllNfts() external onlyAdmin() {
        for (uint p = 0; p < _availableTokens.length; p++) {
            require(
                ERC1155(nftContractAddress).balanceOf(address(this), _availableTokens[p].id) > 0,
                "NFT is owned by this contract"
            );
            ERC1155(nftContractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _availableTokens[p].id,
                _availableTokens[p].amount,
                '0x0'
            );
            delete _availableTokens[p];
            emit NftTransfered(_availableTokens[p].id, msg.sender, block.timestamp);
        }
    }

    /**
     * take eth and distribute NFT
     */
    function deposit() public payable {
        require(msg.value == 0.25 ether, "Please transfer 0.25 ether");
        require(
            _buyers[msg.sender] == false,
            "Only 1 purchase per wallet allowed"
        );
        require(
            _whitelisted[msg.sender] == true,
            "You need to be whitelisted to purchase"
        );
        require(
            _availableTokens.length > 0,
            "Currently no NFT available. Please try again later"
        );

        uint256 randomIndex = randomAvailableTokenIndex();
        uint256 randomTokenId = _availableTokens[randomIndex].id;
        require(
            _availableTokens[randomIndex].amount > 0,
            "No Amount available for this token"
        );
        transferNft(randomTokenId, msg.sender);
        _buyers[msg.sender] = true;
        if (_availableTokens[randomIndex].amount > 1) {
            _availableTokens[randomIndex] = AvailableToken({
                id: randomTokenId,
                amount: _availableTokens[randomIndex].amount - 1
            });
        } else {
            delete _availableTokens[randomIndex];
        }
    }

    /**

     *
     * @param nftId - nftId of the artwork
     * @param to - address of the artwork recipient
     */
    function transferNft(uint256 nftId, address to) private {
        require(
            ERC1155(nftContractAddress).balanceOf(address(this), nftId) > 0,
            "NFT is owned by this contract"
        );
        ERC1155(nftContractAddress).safeTransferFrom(
            address(this),
            to,
            nftId,
            1,
            '0x0'
        );
        emit NftTransfered(nftId, to, block.timestamp);
    }

    // Admin Functions
    /**
    * ERC1155 Receiver Methods
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes memory
    ) public virtual returns (bytes4) {
        require(
            _admins[_from] || _from == owner(),
            "Only Admins can send NFTs"
        );

        int selectedIdx = getAvailableTokensByTokenId(_id);
        if (selectedIdx > 0) {
            uint256 tokenIdx = uint256(selectedIdx);
            _availableTokens[tokenIdx] = AvailableToken({
                id: _id,
                amount: _availableTokens[tokenIdx].amount + _amount
            });
        } else {
            _availableTokens.push(AvailableToken({id: _id, amount: _amount}));
        }

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory
    ) public virtual returns (bytes4) {
        require(
            _admins[_from] || _from == owner(),
            "Only Admins can send NFTs"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            int selectedIdx = getAvailableTokensByTokenId(_ids[i]);
            if (selectedIdx > 0) {
                uint256 tokenIdx = uint256(selectedIdx);
                _availableTokens[tokenIdx] = AvailableToken({
                    id: _ids[i],
                    amount: _availableTokens[tokenIdx].amount + _amounts[i]
                });
            } else {
                _availableTokens.push(
                    AvailableToken({id: _ids[i], amount: _amounts[i]})
                );
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

    // Utils
    /**
     * Helper Function to get Available Token by Token Id
     */
    function getAvailableTokensByTokenId(uint256 id)
        public
        view
        returns (int)
    {
        int index = -1;
        for (uint p = 0; p < _availableTokens.length; p++) {
            if (_availableTokens[p].id == id) {
                index = int(p);
            }
        }
        return index;
    }

    /**
     * Get a random Token Index based on array length
     */
    function randomAvailableTokenIndex() private view returns (uint8) {
        uint256 max_amount = _availableTokens.length;
        return
            uint8(
                uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) %
                    max_amount
            );
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Whitelist
     */
    function addToWhitelist(address _address) public onlyAdmin() {
        _whitelisted[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addMultipleToWhitelist(address[] memory addrs) public onlyAdmin() {
         for (uint p = 0; p < addrs.length; p++) {
            _whitelisted[addrs[p]] = true;
        }
        emit AddedMultipleToWhitelist(addrs);
    }

    function removeFromWhitelist(address _address) public onlyAdmin() {
        _whitelisted[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return _whitelisted[_address];
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
