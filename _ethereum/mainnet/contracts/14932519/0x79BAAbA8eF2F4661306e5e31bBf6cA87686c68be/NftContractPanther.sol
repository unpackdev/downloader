// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

contract PantherNft is ERC721, EIP712, Ownable {
    string public baseURI;
    uint96 public royaltyFeesInBips;
    address public royaltyAddress;
    bool public publicAllowed = false;
    uint120 public MAX_SUPPLY = 1000;
    uint256 public mintCost;
    string private constant SIGNING_DOMAIN = "PANTHER_CON";
    string private constant SIGNATURE_VERSION = "1";
    address private signAddress;
    bool pauseMint = false;
    uint256 private supplyLeft = 1000;

    mapping(uint256 => uint256) private randNumber;
    mapping(address => bool) public availed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _base,
        uint256 mint_cost,
        uint96 _fees,
        address _signAddress
    ) ERC721(_name, _symbol) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        baseURI = _base;
        require(_fees <= 10000, "cannot exceed 10000");
        royaltyFeesInBips = _fees;
        royaltyAddress = msg.sender;
        mintCost = mint_cost;
        signAddress = _signAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function setSignAddress(address _signAddress) external onlyOwner {
        signAddress = _signAddress;
    }

    function setMintCost(uint256 val) external onlyOwner {
        mintCost = val;
    }

    function setPauseMint(bool val) external onlyOwner {
        pauseMint = val;
    }

    function mintWhitelist(uint256 val, bytes memory signature) public payable {
        require(pauseMint == false, "Minting is paused");
        uint256 q = supplyLeft;
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }
        require(val <= 10000, "MAX DISCOUNT IS 10000");
        require(
            check(msg.sender, val, signature) == signAddress,
            "Invalid signature"
        );
        unchecked {
            _balanceOf[msg.sender]++;
        }
        if (val > 0) {
            bool flag = availed[msg.sender];
            availed[msg.sender] = true;
            require(flag == false, "Discount already applied");
        }
        if (val < 10000) {
            uint256 toPay = ((10000 - val) * (mintCost)) / 10000;
            require(msg.value >= toPay, "Not engough eth");
        }
        if (val == 0) {
            require(msg.value >= mintCost, "Not engough eth");
        }
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    q,
                    block.difficulty
                )
            )
        ) % q;

        unchecked {
            id++;
        }

        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = msg.sender;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), msg.sender, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = msg.sender;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), msg.sender, v);
        }
    }

    function check(
        address to,
        uint256 val,
        bytes memory signature
    ) public view returns (address) {
        return _verify(to, val, signature);
    }

    function _verify(
        address to,
        uint256 val,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hash(to, val);
        return ECDSA.recover(digest, signature);
    }

    function _hash(address to, uint256 val) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("PantherStruct(address to,uint256 val)"),
                        to,
                        val
                    )
                )
            );
    }

    function mintOwner(address to, uint256 id) external onlyOwner {
        uint256 q = supplyLeft;
        require(id <= q, "Id out of range");
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }
        unchecked {
            _balanceOf[to]++;
        }
        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, v);
        }
    }

    function mintPublic(address to) public payable {
        require(pauseMint == false, "Minting is paused");
        require(msg.value > (mintCost - 1), "Not engough eth");
        require(publicAllowed, "Open minting not allowed");
        uint256 q = supplyLeft;
        require(supplyLeft >= 1, "Max supply reached");
        unchecked {
            supplyLeft--;
        }

        uint256 id = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    block.difficulty,
                    q
                )
            )
        ) % q;

        unchecked {
            id++;
        }

        if (randNumber[id] == 0) {
            require(ownerOf[id] == address(0), "Already minted");
            ownerOf[id] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, id);
        } else {
            uint256 v = randNumber[id];
            require(ownerOf[v] == address(0), "Already minted");
            ownerOf[v] = to;
            if (randNumber[q] == 0) {
                randNumber[id] = q;
            } else {
                randNumber[id] = randNumber[q];
            }
            emit Transfer(address(0), to, v);
        }
        unchecked {
            _balanceOf[to]++;
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function setPublicMint(bool _status) external onlyOwner {
        publicAllowed = _status;
    }

    function setRoyaltyInfo(address _royaltyAddress, uint96 _royaltyFeesInBips)
        external
        onlyOwner
    {
        require(_royaltyFeesInBips <= 10000, "cannot exceed 10000");
        royaltyAddress = _royaltyAddress;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function withdrawEth() external onlyOwner {
        address payable own = payable(owner());
        (bool success, ) = payable(own).call{value: address(this).balance}("");
        require(success, "Transaction failed");
    }
}
