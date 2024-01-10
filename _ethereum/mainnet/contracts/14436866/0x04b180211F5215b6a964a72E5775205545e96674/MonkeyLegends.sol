// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./MKLockRegistry.sol";
import "./ERC721A.sol";

/*
                       j╫╫╫╫╫╫ ]╫╫╫╫╫H                                          
                        ```╫╫╫ ]╫╫````                                          
    ▄▄▄▄      ▄▄▄▄  ÑÑÑÑÑÑÑ╫╫╫ ]╫╫ÑÑÑÑÑÑÑH ▄▄▄▄                                 
   ▐████      ████⌐ `````````` ``````````  ████▌                                
   ▐█████▌  ▐█████⌐▐██████████ ╫█████████▌ ████▌▐████ ▐██████████ ████▌ ████▌   
   ▐██████████████⌐▐████Γ▐████ ╫███▌└████▌ ████▌ ████ ▐████│█████ ████▌ ████▌   
   ▐████▀████▀████⌐▐████ ▐████ ╫███▌ ████▌ █████████▄ ▐██████████ ████▌ ████▌   
   ▐████ ▐██▌ ████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████│││││└ ██████████▌   
   ▐████      ████⌐▐██████████ ╫███▌ ████▌ ████▌▐████ ▐██████████ ▀▀▀▀▀▀████▌   
    ''''      ''''  '''''''''' `'''  `'''  ''''  ''''  '''''''''` ██████████▌   
╓╓╓╓  ╓╓╓╓  ╓╓╓╓                              .╓╓╓╓               ▀▀▀▀▀▀▀▀▀▀Γ   ===
████▌ ████=▐████                              ▐████                             
████▌ ████= ▄▄▄▄ ▐█████████▌ ██████████▌▐██████████ ║█████████▌ ███████▌▄███████
█████▄███▀ ▐████ ▐████▀████▌ ████▌▀████▌▐████▀▀████ ║████▀████▌ ████▌▀████▀▀████
█████▀████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ █████▄████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ ▀▀▀▀▀▀████▌▐██████████ ║█████████▌ ████▌ ████=▐████
▀▀▀▀` ▀▀▀▀  └└└└ `▀▀▀▀ "▀▀▀╘ ▄▄▄▄▄▄████▌ ▀▀▀▀▀▀▀▀▀▀ `▀▀▀▀▀▀▀▀▀└ ▀▀▀▀` ▀▀▀▀  ▀▀▀▀
                             ▀▀▀▀▀▀▀▀▀▀U                                      
*/

contract MonkeyLegends is MKLockRegistry, ERC721A {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant NUM_RESERVED = 11;

    address public authSigner;
    uint256 public mintPrice = 0.3 ether;

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    constructor(
        address _erc20Token,
        address _authSigner
    ) ERC721A("Monkey Legends", "MKL") {
        peach = IERC20(_erc20Token);
        authSigner = _authSigner;
        baseURI = "https://meta.monkeykingdom.io/3/";
        super._safeMint(_msgSender(), NUM_RESERVED);
    }

    // renaming
    uint256 public renamePrice = 100 ether;
    mapping(uint256 => string) public tokenName;

    function setRenamePrice(uint256 _price) external onlyOwner {
        renamePrice = _price;
    }

    function validName(string memory s) public pure returns (bool) {
        bytes memory b = bytes(s);
        require(b.length > 0 && b.length <= 32, "Invalid length");
        unchecked {
            uint256 i = 0;
            while (i < b.length) {
                if (b[i] >> 7 == 0) {
                    if (b[i] < 0x20 || b[i] > 0x7e) return false;
                    i += 1;
                } else if (b[i] >> 5 == bytes1(uint8(0x6))) i += 2;
                else if (b[i] >> 4 == bytes1(uint8(0xE))) i += 3;
                else if (b[i] >> 3 == bytes1(uint8(0x1E))) i += 4;
                else i += 1;
            }
        }
        return true;
    }

    function rename(uint256 tokenId, string memory newName) external {
        require(_msgSender() == ownerOf(tokenId), "Only rename your own NFTs");
        require(
            sha256(bytes(newName)) != sha256(bytes(tokenName[tokenId])),
            "No name change necessary"
        );
        require(validName(newName), "Invalid name");
        peach.transferFrom(_msgSender(), address(this), renamePrice);
        tokenName[tokenId] = newName;
    }

    // breeding
    uint256 public constant MAX_BREED = 4442;
    uint256 public numMonkeysBreeded = 0;
    mapping(string => uint256) public wukongsBreedCount;
    mapping(string => uint256) public baepesBreedCount;
    mapping(string => bool) public peachUsed;

    function breed(
        string calldata mkHash,
        string calldata dbHash,
        string calldata peachHash,
        bytes calldata sig
    ) external {
        require(numMonkeysBreeded + 1 <= MAX_BREED, "Max no. breed reached");
        bytes memory b = abi.encodePacked(
            mkHash,
            dbHash,
            peachHash,
            _msgSender()
        );
        require(recoverSigner(keccak256(b), sig) == authSigner, "Invalid sig");

        unchecked {
            require(wukongsBreedCount[mkHash] < 2, "Wukong breed twice");
            wukongsBreedCount[mkHash]++;
            require(baepesBreedCount[dbHash] < 2, "Baepe breed twice");
            baepesBreedCount[dbHash]++;
            require(!peachUsed[peachHash], "Peach has been used");
            peachUsed[peachHash] = true;
        }

        super._safeMint(_msgSender(), 1);
        numMonkeysBreeded++;
    }

    // whitelist
    uint256 public constant MAX_WHITELIST_MINT = 3000;
    uint256 public numWhitelistMint;
    mapping(uint256 => mapping(address => bool)) public whitelistClaimed;
    uint256 public currentWhitelistTier = 1;

    function setCurrentWhitelistTier(uint256 tier) external onlyOwner {
        require(tier > currentWhitelistTier, "tier can only go up");
        currentWhitelistTier = tier;
    }

    function mintSignedWhitelist(uint256 tier, bytes calldata sig)
        external
        payable
    {
        unchecked {
            require(
                numWhitelistMint + 1 <= MAX_WHITELIST_MINT,
                "Whitelist mint finished"
            );
            require(tier == currentWhitelistTier, "Invalid tier");
            bytes memory b = abi.encodePacked(tier, _msgSender());
            require(
                recoverSigner(keccak256(b), sig) == authSigner,
                "Invalid sig"
            );
            require(
                whitelistClaimed[currentWhitelistTier][_msgSender()] == false,
                "Whitelist quota used"
            );
            whitelistClaimed[currentWhitelistTier][_msgSender()] = true;
            require(msg.value >= mintPrice, "Insufficient ETH");
        }
        super._safeMint(_msgSender(), 1);
        numWhitelistMint++;
    }

    // claim
    IERC20 public peach;
    uint256 public claimPrice = 0;

    function setClaimPrice(uint256 _claimPrice) external onlyOwner {
        claimPrice = _claimPrice;
    }

    function claim(uint256 n) external {
        require(claimPrice > 0, "Claiming not open");
        peach.transferFrom(_msgSender(), address(this), claimPrice * n);
        require(_currentIndex + n < MAX_SUPPLY, "MAX");
        super._safeMint(_msgSender(), n);
    }

    // withdraw
    function withdrawAll() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
        peach.transferFrom(
            address(this),
            _msgSender(),
            peach.balanceOf(address(this))
        );
    }

    // locking
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override(ERC721A) {
        require(isUnlocked(startTokenId), "Token locked");
    }

    // metadata
    string public baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    // crypto
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "invalid sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
}
