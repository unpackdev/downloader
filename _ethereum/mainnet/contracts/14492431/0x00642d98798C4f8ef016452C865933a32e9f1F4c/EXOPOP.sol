// SPDX-License-Identifier: MIT
// Creator: EXO TEAM
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721A.sol";

contract EXOPOP is Initializable, OwnableUpgradeable, ERC721A, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    address private withdrawWallet;

    mapping(address => uint256) public allowlist;

    function initialize(
        string memory name_,
        string memory symbol_,
        address withdrawWallet_
    ) public initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        withdrawWallet = withdrawWallet_;
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function award(address[] memory _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function redeem() external nonReentrant {
        require(allowlist[msg.sender] > 0, "You have no tokens to redeem");
        _safeMint(msg.sender, allowlist[msg.sender]);
        allowlist[msg.sender] = 0;
    }

    function setAllowlist(address[] memory _allowlist) external onlyOwner {
        for (uint256 i = 0; i < _allowlist.length; i++) {
            allowlist[_allowlist[i]] = 1;
        }
    }

    function removeFromAllowlist(address[] memory _allowlist) external onlyOwner {
        for (uint256 i = 0; i < _allowlist.length; i++) {
            allowlist[_allowlist[i]] = 0;
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function version() external pure returns (string memory) {
        return "1.0.3";
    }
}
