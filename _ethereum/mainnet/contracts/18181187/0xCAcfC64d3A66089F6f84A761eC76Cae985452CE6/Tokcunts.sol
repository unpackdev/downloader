// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Upgradeable.sol";
import "./IEIP2981.sol";
import "./Strings.sol";

import "./console.sol";

contract Tokcunts is ERC721Upgradeable {
    uint256 public royaltyAmount;
    address public royalties_recipient;
    string public constant contractName = "Tokcunts";
    mapping(address => bool) isAdmin;
    mapping(uint256 => bool) public isCirculated;
    string frontURIS;
    string backURIS;
    string agedFrontURIS;
    string agedBackURIS;
    bool revealed;
    bool public shitUnlocked;
    bool public diamondUnlocked;
    uint256 public generalSupply;
    uint256 public shitSupply;
    uint256 public diamondSupply;
    uint256 public tokenId;
    uint256 public shitId;
    uint256 public diamondId;

    error AlreadyCirculated();
    error IncorrectTokenCount();
    error Locked();
    error SoldOut();
    error Unauthorized();

    function initialize() public initializer {
        __ERC721_init("Tokcunts", "Tokcunts");
        generalSupply = 5151;
        shitSupply = 111;
        diamondSupply = 55;
        tokenId = 0;
        shitId = 0;
        diamondId = 0;
        royaltyAmount = 10;
        royalties_recipient = msg.sender;
        isAdmin[msg.sender] = true;
    }

    modifier adminRequired() {
        if (!isAdmin[msg.sender]) revert Unauthorized();
        _;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable) returns (bool) {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IEIP2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(address _to) external adminRequired {
        if (tokenId >= generalSupply) revert SoldOut();
        _mint(_to, tokenId);
        tokenId++;
    }

    function tests() external pure returns (bool) {
        return true;
    }

    function getShit(
        address _to,
        uint256[] calldata _tokensToCirculate
    ) external {
        if (!shitUnlocked) revert Locked();
        if (shitId >= shitSupply) revert SoldOut();
        if (_tokensToCirculate.length != 3) revert IncorrectTokenCount();
        for (uint16 i = 0; i < _tokensToCirculate.length; i++) {
            uint256 _tokenId = _tokensToCirculate[i];
            if (ownerOf(_tokenId) != msg.sender) revert Unauthorized();
            if (isCirculated[_tokenId]) revert AlreadyCirculated();
            isCirculated[_tokenId] = true;
        }
        console.log(generalSupply + shitId);
        _mint(_to, generalSupply + shitId);
        shitId++;
    }

    function getDiamond(
        address _to,
        uint256[] calldata _tokensToCirculate
    ) external {
        if (!diamondUnlocked) revert Locked();
        if (diamondId >= diamondSupply) revert SoldOut();
        if (_tokensToCirculate.length != 11) revert IncorrectTokenCount();
        for (uint16 i = 0; i < _tokensToCirculate.length; i++) {
            uint256 _tokenId = _tokensToCirculate[i];
            if (ownerOf(_tokenId) != msg.sender) revert Unauthorized();
            if (isCirculated[_tokenId]) revert AlreadyCirculated();
            isCirculated[_tokenId] = true;
        }
        _mint(_to, generalSupply + shitSupply + diamondId);
        diamondId++;
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function toggleShitLock() external adminRequired {
        shitUnlocked = !shitUnlocked;
    }

    function toggleDiamondLock() external adminRequired {
        diamondUnlocked = !diamondUnlocked;
    }

    function circulate(uint256 _tokenId) external adminRequired {
        if (isCirculated[_tokenId]) revert AlreadyCirculated();
        isCirculated[_tokenId] = true;
    }

    function circulateMany(
        uint256[] calldata _tokenIds
    ) external adminRequired {
        _circulateMany(_tokenIds);
    }

    function _circulateMany(uint256[] calldata _tokenIds) internal {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (isCirculated[_tokenId]) revert AlreadyCirculated();
            isCirculated[_tokenId] = true;
        }
    }

    function reveal() external adminRequired {
        revealed = !revealed;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (isCirculated[_tokenId]) {
            if ((block.number / 50) % 2 == 0 || !revealed) {
                return
                    string.concat(
                        agedFrontURIS,
                        Strings.toString(_tokenId),
                        ".json"
                    );
            } else {
                return
                    string.concat(
                        agedBackURIS,
                        Strings.toString(_tokenId),
                        ".json"
                    );
            }
        } else {
            if ((block.number / 50) % 2 == 0 || !revealed) {
                return
                    string.concat(
                        frontURIS,
                        Strings.toString(_tokenId),
                        ".json"
                    );
            } else {
                return
                    string.concat(
                        backURIS,
                        Strings.toString(_tokenId),
                        ".json"
                    );
            }
        }
    }

    function setURI(
        string calldata _newURI,
        bool _isFront,
        bool _isCirculated
    ) external adminRequired {
        if (_isFront) {
            if (_isCirculated) {
                agedFrontURIS = _newURI;
            } else {
                frontURIS = _newURI;
            }
        } else {
            if (_isCirculated) {
                agedBackURIS = _newURI;
            } else {
                backURIS = _newURI;
            }
        }
    }

    function setRoyalties(
        address payable _recipient,
        uint256 _royaltyPerCent
    ) external adminRequired {
        royalties_recipient = _recipient;
        royaltyAmount = _royaltyPerCent;
    }

    function royaltyInfo(
        uint256 salePrice
    ) external view returns (address, uint256) {
        if (royalties_recipient != address(0)) {
            return (royalties_recipient, (salePrice * royaltyAmount) / 100);
        }
        return (address(0), 0);
    }

    function withdraw(address recipient) external adminRequired {
        payable(recipient).transfer(address(this).balance);
    }
}
