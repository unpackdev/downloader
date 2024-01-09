// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./SafeMath.sol";


/// @custom:security-contact bozp.dev@gmail.com
contract NftWatcher is ERC1155, AccessControl, Pausable, ERC1155Supply {
    using SafeMath for uint256;
    
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant ALPHA_ROLE = keccak256("ALPHA_ROLE");
    bytes32 private constant BETA_ROLE = keccak256("BETA_ROLE");
    bytes32 private constant PRESALE_ROLE = keccak256("PRESALE_ROLE");

    uint256 private constant BASE_ID = 0;
    uint256 private constant PLUS_ID = 1;
    uint256 private constant PRO_ID = 2;

    string private name = "nft watcher";
    string private symbol = "nw";
    string private _uri = "";

    uint256 public currentCount = 0;
    uint256 public constant maxCount = 2000;

    uint256 private constant maxBaseCount = 1500;
    uint256 private constant maxPlusCount = 450;
    uint256 private constant maxProCount = 50;

    uint256 private baseCount = 0;
    uint256 private plusCount = 0;
    uint256 private proCount = 0;

    uint256 private constant minMintCount = 1;
    uint256 private constant maxMintCount = 3;

    uint256 private constant salePrice = 0.1 ether;
    uint256 private constant betaPrice = 0.05 ether;
    uint256 private constant alphaPrice = 0 ether;

    bool alphaSale = false;
    bool betaSale = false;
    bool presale = false;
    bool sale = false;

    event priceChanged(uint256 newPrice);

    mapping (address => bool) alphaMinterMinted;
    mapping (address => bool) betaMinterMinted;
    mapping (address => bool) presaleMinterMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(ALPHA_ROLE, msg.sender);
        _grantRole(PRESALE_ROLE, msg.sender);
    }

    function getTier(uint256 index) private returns(uint256) {
        uint256 timestamp = block.timestamp + index;
        uint256 seed = uint256(keccak256(abi.encodePacked(
            timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (timestamp)) +
            block.number
        )));

        uint256 passValue = (seed - ((seed / 200) * 200));

        if ( passValue <= 5 && proCount <= maxProCount ) {
            proCount++;
            return 2;
        }
        else if ( passValue <= 50 && plusCount <= maxPlusCount ) {
            plusCount++;
            return 1;
        }
        else {
            baseCount++;
            return 0;
        }
    }

    function setURI(string memory newuri) public onlyRole(OWNER_ROLE) {
        _uri = newuri;
        _setURI(newuri);
    }

    
    function uri(uint _tokenID) override public view returns (string memory) {
        return string(
        abi.encodePacked(
                _uri,
                uint2str(_tokenID),
                ".json"
            ) 
        );
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    // toggle normal sale
    function toggleSales() public onlyRole(OWNER_ROLE) {
        if ( ! sale ) {
            alphaSale = false;
            betaSale = false;
            presale = false;
            sale = true;
            emit priceChanged(salePrice);
        }
        else {
            sale = false;
        }
    }

    // Toggle the alpha sales system
    function toggleAlphaSales() public onlyRole(OWNER_ROLE) {
        if ( ! alphaSale ) {
            alphaSale = true;
            betaSale = false;
            presale = false;
            sale = false;
            emit priceChanged(alphaPrice);
        }
        else {
            alphaSale = false;
        }
    }

    // Toggle the beta sales system
    function toggleBetaSales() public onlyRole(OWNER_ROLE) {
        if ( ! betaSale ) {
            alphaSale = false;
            betaSale = true;
            presale = false;
            sale = false;
            emit priceChanged(betaPrice);
        }
        else {
            betaSale = false;
        }
    }

    // Toggle the beta sales system
    function togglePreSales() public onlyRole(OWNER_ROLE) {
        if ( ! presale ) {
            alphaSale = false;
            betaSale = false;
            presale = true;
            sale = false;
            emit priceChanged(salePrice);
        }
        else {
            betaSale = false;
        }
    }

    function addAlphaWhitelist(address[] memory alphas) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < alphas.length; i++) {
            _grantRole(ALPHA_ROLE, alphas[i]);
        }
    }

    function removeAlphaWhitelist(address[] memory alphas) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < alphas.length; i++) {
            _revokeRole(ALPHA_ROLE, alphas[i]);
        }
    }

    function addBetaWhitelist(address[] memory betas) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < betas.length; i++) {
            _grantRole(BETA_ROLE, betas[i]);
        }
    }

    function removeBetaWhitelist(address[] memory betas) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < betas.length; i++) {
            _revokeRole(BETA_ROLE, betas[i]);
        }
    }

    function addPresale(address[] memory pre) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < pre.length; i++) {
            _grantRole(PRESALE_ROLE, pre[i]);
        }
    }

    function removePresale(address[] memory pre) public onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < pre.length; i++) {
            _revokeRole(PRESALE_ROLE, pre[i]);
        }
    }

    function alphaMint()
        public payable onlyRole(ALPHA_ROLE)
    {
        require(alphaSale == true, "Alpha Sale has not started");
        require(currentCount < maxCount, "All passes have been minted");
        require(alphaMinterMinted[msg.sender] == false, "Alpha Minter has already minted");
        uint256 id = getTier(0);

        alphaMinterMinted[msg.sender] = true;
        currentCount++;
        _mint(msg.sender, id, minMintCount, "");
    }

    function betaMint()
        public payable onlyRole(BETA_ROLE)
    {
        require(betaSale == true, "Beta Sale has not started");
        require(currentCount < maxCount, "All passes have been minted");
        require(betaMinterMinted[msg.sender] == false, "Beta Minter has already minted");
        require(msg.value >= betaPrice, "Not enough Eth");
        uint256 id = getTier(0);

        betaMinterMinted[msg.sender] = true;
        currentCount++;
        _mint(msg.sender, id, minMintCount, "");
    }

    function presaleMint( uint256 count )
        public payable onlyRole(PRESALE_ROLE)
    {
        require(presale == true, "Pre Sale has not started");
        require(currentCount < maxCount, "All passes have been minted");
        require(presaleMinterMinted[msg.sender] == false, "Pre Minter has already minted");
        require(msg.value >= salePrice.mul(count), "Not enough Eth");

        presaleMinterMinted[msg.sender] = true;
        for (uint256 i = 0; i < count; i++) {
            uint256 id = getTier(i);

            currentCount++;
            _mint(msg.sender, id, 1, "");
        }
    }

    function mint( uint256 count )
        public payable
    {
        require(sale == true, "Sale has not started");
        require(count >= minMintCount && count <= maxMintCount, "Allowed mint count is between 1-3");
        require(currentCount < maxCount, "All passes have been minted");
        require(msg.value >= salePrice.mul(count), "Not enough Eth");
        // require(msg.value == salePrice.mul(count), "Too much Eth, price to mint is 0.1 Eth. If you are minting 3, your price must be 0.15 Eth.");

        for (uint256 i = 0; i < count; i++) {
            uint256 id = getTier(i);

            currentCount++;
            _mint(msg.sender, id, 1, "");
        }
    }

    function checkAlphaWhitelist(address target_address) public view returns(bool) {
        return hasRole(ALPHA_ROLE, target_address);
    }

    function checkBetaWhitelist(address target_address) public view returns(bool) {
        return hasRole(BETA_ROLE, target_address);
    }

    function checkPresaleWhitelist(address target_address) public view returns(bool) {
        return hasRole(PRESALE_ROLE, target_address);
    }

    function checkAlphaMinted(address target_address) public view returns(bool) {
        return alphaMinterMinted[target_address];
    }

    function checkBetaMinted(address target_address) public view returns(bool) {
        return betaMinterMinted[target_address];
    }

    function checkPresaleMinted(address target_address) public view returns(bool) {
        return presaleMinterMinted[target_address];
    }

    function getCurrentCount() public view returns(uint256) {
        return currentCount;
    }

    function totalSupply() public pure returns(uint256) {
        return maxCount;
    }

    function saleActive() public view returns(bool) {
        return sale;
    }

    function alphaSaleActive() public view returns(bool) {
        return alphaSale;
    }

    function betaSaleActive() public view returns(bool) {
        return betaSale;
    }

    function preSaleActive() public view returns(bool) {
        return presale;
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function withdrawFunds() public onlyRole(OWNER_ROLE) {
		payable(msg.sender).transfer(address(this).balance);
	}
}
