// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract EthemeralArt is ERC721Burnable, Ownable {

    event DelegateChange(address indexed delegate, bool add);
    event AllowDelegatesChange(address indexed user, bool allow);

    string private _uri;

    address public minter;
    // Delegates include game masters and auction houses
    mapping(address => bool) private delegates;

    // Default to off. User needs to allow
    mapping(address => bool) private allowDelegates;

    constructor() ERC721("Ethemerals - Art", "ART") {
        _uri = 'https://api.ethemerals.com/api/art/';
        minter = msg.sender;
    }

    /**
     * @dev Set or unset delegates
     */
    function setAllowDelegates(bool allow) external {
        allowDelegates[msg.sender] = allow;
        emit AllowDelegatesChange(msg.sender, allow);
    }

    /**
    * @dev mints only minter
    * requires minter to be active
    */
    function mint(address to, uint256 tokenId) external {
        // ADMIN
        require(minter == msg.sender, "minter only");
        _safeMint(to, tokenId);
    }

    function mintAmounts(address to, uint256 startingTokenId, uint256 amount) external {
        // ADMIN
        require(minter == msg.sender, "minter only");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, startingTokenId + i);
        }
    }

    function changeMinter(address _minter) external onlyOwner {
        // ADMIN
        minter = _minter;
    }

    function addDelegate(address _delegate, bool add) external onlyOwner {
        // ADMIN
        delegates[_delegate] = add;
        emit DelegateChange(_delegate, add);
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        // ADMIN
        _uri = newuri;
    }

    //VIEW
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     * White list for game masters and auction house
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (allowDelegates[_owner] && (delegates[_operator] == true)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}
