// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ERC721PsiBurnable.sol";

contract TokenineNFT is ERC721PsiBurnable, AccessControl, Ownable, Pausable , IERC2981 {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    modifier mintable(uint256 _mintAmount) {
        require(_mintAmount > 0, "TokenineNFT: amount must not be 0");
        require(
            _mintAmount <= maxMintAmount,
            "TokenineNFT: reach to minted limit"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "TokenineNFT: supply reach to limit"
        );
        require(
            totalSupply() + _mintAmount <= softcap,
            "TokenineNFT: softcap limited"
        );
        _;
    }

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public cost;
    uint256 public presaleCost;

    mapping(address => uint256) public costs;
    mapping(address => uint256) public presaleCosts;

    uint256 public maxSupply;
    uint256 public softcap;
    uint256 public maxMintAmount;
    uint256 public royaltyFee;

    bool public publicSale;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;

    address public feeCollector;
    address private _recipient;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _softcap,
        uint256 _cost,
        uint256 _presaleCost,
        string memory _initBaseURI,
        address _feeCollector
    )  ERC721Psi(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setBaseURI(_initBaseURI);
        _pause();
        maxSupply = _maxSupply;
        softcap = _softcap;
        cost = _cost;
        presaleCost = _presaleCost;
        feeCollector = _feeCollector;
        publicSale = true;
        maxMintAmount = 10;
        _recipient = msg.sender;
        royaltyFee = 1000;
    }

    // Internal functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory _newBaseURI) internal {
        baseURI = _newBaseURI;
    }

    function _sendNative(address _receiver, uint256 _amount) internal {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success, "TokenineNFT: failed to send native");
    }

    // External functions

    function mint(uint256 _mintAmount)
        external
        payable
        whenNotPaused
        mintable(_mintAmount)
    {
        if (publicSale) {
            require(
                msg.value >= cost.mul(_mintAmount),
                "TokenineNFT: amount in valid"
            );
        } else if (presaleWallets[msg.sender]) {
            require(
                msg.value >= presaleCost.mul(_mintAmount),
                "TokenineNFT: amount in valid"
            );
        } else if (whitelisted[msg.sender]) {
            require(
                msg.value >= cost.mul(_mintAmount),
                "TokenineNFT: amount in valid"
            );
        } else {
            revert("TokenineNFT: Not selling");
        }
        _sendNative(feeCollector, msg.value);
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount, address _token)
        external
        whenNotPaused
        mintable(_mintAmount)
    {
        require(
            costs[_token] != 0 && presaleCosts[_token] != 0,
            "TokenineNFT: token not supported"
        );
        if (publicSale) {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                feeCollector,
                costs[_token].mul(_mintAmount)
            );
        } else if (presaleWallets[msg.sender]) {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                feeCollector,
                presaleCosts[_token].mul(_mintAmount)
            );
        } else if (whitelisted[msg.sender]) {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                feeCollector,
                costs[_token].mul(_mintAmount)
            );
        } else {
            revert("TokenineNFT: Not selling");
        }
        _safeMint(msg.sender, _mintAmount);
    }

    // View functions

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // OnlyAdmin functions

    function mintByAdmin(address _to, uint256 _mintAmount)
        external
        mintable(_mintAmount)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _safeMint(_to, _mintAmount);
    }

    function burn(uint256 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(_tokenId);
    }

    function setBaseURI(string memory _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(_newBaseURI);
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxMintAmount = _newMaxMintAmount;
    }

    function setSoftcap(uint256 _newSoftcap)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        softcap = _newSoftcap;
    }

    function setCost(uint256 _newCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presaleCost = _newCost;
    }

    function setPublicSale(bool _publicSale)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        publicSale = _publicSale;
    }

    function setCosts(address _token, uint256 _newCost)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        costs[_token] = _newCost;
    }

    function setPresaleCosts(address _token, uint256 _newCost)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presaleCosts[_token] = _newCost;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseExtension = _newBaseExtension;
    }

    function whitelistUser(address _user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelisted[_user] = false;
    }

    function addPresaleUser(address _user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presaleWallets[_user] = true;
    }

    function addPresaleUsers(address[] calldata _users)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _users.length; i++) {
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        presaleWallets[_user] = false;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Override functions

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Psi, IERC165)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoyalties(newRecipient);
    }
    // royaltyFee
    function setroyaltyFee(uint256 _royaltyFee) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_royaltyFee <= 10000, 'ERC2981Royalties: Too high');
        royaltyFee = _royaltyFee;
    }
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 1000) / 10000);
    }
}
