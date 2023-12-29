// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AC.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./OwnableBasic.sol";
import "./Strings.sol";

contract MDD is ERC721AC, OwnableBasic, ReentrancyGuard {
    event MintSuccess(uint256 tokenId, uint256 amount);

    enum MintType {
        ALLOWLIST,
        PUBLIC
    }

    address public signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;

    bool public paused = true;

    string public metadata = "ipfs://Qmbe8E6pVtwYxdMWkEDgLbzu9rTqt3Yf8fqe9a8Q6ZqM5t/";

    uint256 constant MAX_SUPPLY = 5000;
    uint256 public maxAllowlist = 1000;

    mapping(MintType => uint256) public mintCost;
    mapping(MintType => uint256) public mintMax;

    mapping(MintType => bool) public mintActive;

    mapping(MintType => mapping(address => uint256)) public typeToWalletMinted;

    bool public isBurnActive = false;

    uint256 public allowlistMinted;

    mapping(uint16 => uint16) public tokenToType;
    mapping(uint16 => bool) public genesisMinted;

    Payments[] public payments;

    address lastSender;

    struct Payments {
        address to;
        uint256 percent;
    }

    constructor() ERC721AC("Megadeth Digital", "MDD") {
        
        mintCost[MintType.ALLOWLIST] = 0.06 ether;
        mintCost[MintType.PUBLIC] = 0.1 ether;

        mintMax[MintType.ALLOWLIST] = 2;
        mintMax[MintType.PUBLIC] = 10;

        mintActive[MintType.ALLOWLIST] = false;
        mintActive[MintType.PUBLIC] = false;

        payments.push(Payments(0x37fBDA81678AC81A6D2c4af662ca5956F2233E6D, 850));
        payments.push(Payments(0xa69B6935B0F38506b81224B4612d7Ea49A4B0aCC, 50));
        payments.push(Payments(0x51fdd7da748EC810c3b3aBF264126AB37b9E5cB6, 50));
        payments.push(Payments(0x34BeE8456e70C91E674Ed1CaacF29d54819153Ff, 25));
        payments.push(Payments(0x051B983476c797D780DAee02f729616a3c92c2bE, 25));

        uint256 basisPoints = 0;

        for (uint i = 0; i < payments.length; i++)
            basisPoints += payments[i].percent;

        require(basisPoints == 1000, "Basis points must equal 1000");
    }

    receive() external payable {}

    function mint(
        address wallet,
        bytes calldata voucher,
        uint256 amount,
        MintType mintType
    ) external payable nonReentrant {
        uint256 costPerMint = mintCost[mintType];
        uint256 maxToMint = mintMax[mintType];

        require(mintActive[mintType], "Mint type not active");

        require(_totalMinted() + amount <= MAX_SUPPLY, "Minted out");

        require(msg.value >= costPerMint * amount, "Ether value sent is not correct");
        require(typeToWalletMinted[mintType][wallet] + amount <= maxToMint, "Too many");

        if (mintType != MintType.PUBLIC) {
            require(allowlistMinted + amount <= maxAllowlist, "Allowlist minted out");

            bytes32 hash = keccak256(abi.encodePacked(wallet));
            require(_verifySignature(signer, hash, voucher), "Invalid voucher");

            allowlistMinted += amount;
        }

        typeToWalletMinted[mintType][wallet] += amount;
        _mint(wallet, amount);

        emit MintSuccess(_totalMinted(), amount);
    }

    function mintAdmin(uint256 amount) external payable nonReentrant onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Minted out");

        _mint(msg.sender, amount);

        emit MintSuccess(_totalMinted(), amount);
    }

    function burn(uint256[] memory tokenIds) public nonReentrant {
        require(isBurnActive);

        for (uint i = 0; i < tokenIds.length; i++) _burn(tokenIds[i], true);
    }

    function _verifySignature(
        address _signer,
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (bool) {
        return
            _signer ==
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(_hash),
                _signature
            );
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setMetadata(string memory _metadata) public onlyOwner {
        metadata = _metadata;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadata;
    }

    function setMintActive(MintType mintType, bool state) public onlyOwner {
        mintActive[mintType] = state;
    }

    function setBurnActive() public onlyOwner {
        isBurnActive = !isBurnActive;
    }

    function setMintCost(MintType mintType, uint256 newCost) public onlyOwner {
        mintCost[mintType] = newCost;
    }

    function setMintMax(MintType mintType, uint256 newMax) public onlyOwner {
        mintMax[mintType] = newMax;
    }

    function updateMaxAllowlist(uint256 newMaxAllowlist) public onlyOwner {
        require(newMaxAllowlist <= MAX_SUPPLY, "New max allowlist must be less than or equal to max supply");
        maxAllowlist = newMaxAllowlist;
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 total = address(this).balance;

        (bool success, ) = payable(owner()).call{value: total}("");
        require(success);
    }

    function withdraw() public onlyOwner {
        uint256 total = address(this).balance;

        for (uint i = 0; i < payments.length; i++)
            _sendETH(payments[i].to, payments[i].percent, total);
    }

    function _sendETH(address to, uint256 percent, uint256 total) internal {
        uint256 toSend = (total * percent) / 1000;

        (bool success, ) = payable(to).call{value: toSend}("");
        require(success);
    }

    function getAmountMintedPerType(
        MintType mintType,
        address _address
    ) public view returns (uint256) {
        return typeToWalletMinted[mintType][_address];
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) {
        require(!paused, "Contract is paused");
        require(isOperatorWhitelisted(operator), "Operator not whitelisted");

        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) {
        require(!paused, "Contract is paused");
        require(isOperatorWhitelisted(operator), "Operator not whitelisted");

        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) {
        require(!paused, "Contract is paused");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) {
        require(!paused, "Contract is paused");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) {
        require(!paused, "Contract is paused");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}
