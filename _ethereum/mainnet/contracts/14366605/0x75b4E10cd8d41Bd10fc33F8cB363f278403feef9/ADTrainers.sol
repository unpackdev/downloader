//SPDX-License-Identifier: MIT
/*
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --
-  ______     __   __     ______     __  __     _____     ______     __    __     __     ______     __   __     -
- /\  __ \   /\ "-.\ \   /\  ___\   /\ \/ /    /\  __-.  /\  __ \   /\ "-./  \   /\ \   /\  __ \   /\ "-.\ \    -
- \ \  __ \  \ \ \-.  \  \ \  __\   \ \  _"-.  \ \ \/\ \ \ \  __ \  \ \ \-./\ \  \ \ \  \ \  __ \  \ \ \-.  \   -
-  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\ \_\  \ \_\ \ \_\  \ \_\  \ \_\ \_\  \ \_\\"\_\  -
-   \/_/\/_/   \/_/ \/_/   \/_____/   \/_/\/_/   \/____/   \/_/\/_/   \/_/  \/_/   \/_/   \/_/\/_/   \/_/ \/_/  -
-                                                                                                               -    
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --


*/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ADTrainers is ERC721A, Ownable {
    address public adBoosterPackAddress;
    uint256 public constant MAX_SUPPLY = 7770;
    bool public revealed;

    // URI settings
    string public baseTokenURI;
    string public placeholderURI;

    // These proxy address will be approved to interact
    // with ADTrainers for future staking and gaming features
    mapping(address => bool) public proxyToApprove;

    constructor(
        address _adBoosterPackAddress,
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        adBoosterPackAddress = _adBoosterPackAddress;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier callerIsADBoosterPack() {
        require(
            msg.sender == adBoosterPackAddress,
            "Caller is not ADBoosterPack contract"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
     * @dev Generic mint function to be called by the ADBoosterPacks contract for both
     * whitelist and public sales.
     * Can only be called by the ADBoosterPacks contract.
     */
    function mint(uint256 _quantity, address _to)
        external
        callerIsADBoosterPack
    {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Max supply has been reached"
        );
        _safeMint(_to, _quantity);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function tokenURI(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_id), "Nonexistent token");

        return revealed ? super.tokenURI(_id) : placeholderURI;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (proxyToApprove[_operator]) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setADBoosterPackAddress(address _adBoosterPackAddress)
        external
        onlyOwner
    {
        adBoosterPackAddress = _adBoosterPackAddress;
    }

    function setBaseURI(string calldata _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    function setPlaceholderURI(string memory _URI) external onlyOwner {
        placeholderURI = _URI;
    }

    function flipRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function flipProxyState(address _proxyAddress) external onlyOwner {
        proxyToApprove[_proxyAddress] = !proxyToApprove[_proxyAddress];
    }
}
