pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./draft-EIP712.sol";
import "./console.sol";

contract UnusualGs is ERC721A, EIP712("AllowList", "1.0") {
    string public BASE_URI;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public ALLOW_PRICE = 50000000000000000;
    uint256 public PRICE = 80000000000000000;
    uint256 public MAX_PER_TX = 3;
    address public CONTRACT_OWNER;
    bytes private PREVIOUS_SIGNATURE = "0";
    bool public PUBLIC_SALE = false;
    bool public PRE_SALE = false;

    struct AllowList {
        address allow;
    }

    constructor(
        string memory baseURI,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        BASE_URI = baseURI;
        CONTRACT_OWNER = msg.sender;
    }

    function togglePreSale() public {
        require(msg.sender == CONTRACT_OWNER, "only owner can call this");
        PRE_SALE = !PRE_SALE;
    }

    function togglePublicSale() public {
        require(msg.sender == CONTRACT_OWNER, "only owner can call this");
        PUBLIC_SALE = !PUBLIC_SALE;
    }

    function setBaseURI(string memory newUri) public {
        require(msg.sender == CONTRACT_OWNER, "only owner can call this");
        BASE_URI = newUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function withdraw() external {
        require(msg.sender == CONTRACT_OWNER, "only owner can call this");
        payable(CONTRACT_OWNER).transfer(address(this).balance);
    }

    function mintAllowList(
        uint256 quantity,
        AllowList memory dataToVerify,
        bytes memory signature
    ) external payable {
        require(PRE_SALE, "Presale not active");
        require(totalSupply() <= MAX_SUPPLY, "Would exceed max supply");
        require(msg.value >= ALLOW_PRICE, "insufficient funds");
        require(quantity <= MAX_PER_TX, "cannot mint that many");
        require(_verifySignature(dataToVerify, signature), "Invalid signature");
         _safeMint(msg.sender, quantity);
        PREVIOUS_SIGNATURE = signature;
    }

    function mint(uint256 quantity) external payable {
        require(PUBLIC_SALE, "Public sale not active");
        require(totalSupply() <= MAX_SUPPLY, "Would exceed max supply");
        require(msg.value >= PRICE, "insufficient funds");
        require(quantity <= MAX_PER_TX, "cannot mint that many");        
        _safeMint(msg.sender, quantity);
    }

    function _verifySignature(
        AllowList memory dataToVerify,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("AllowList(address allow)"),
                    dataToVerify.allow
                )
            )
        );

        require(
            keccak256(bytes(signature)) != keccak256(bytes(PREVIOUS_SIGNATURE)),
            "Invalid nonce"
        );
        require(msg.sender == dataToVerify.allow, "Not on allow list");

        address signerAddress = ECDSA.recover(digest, signature);

        require(CONTRACT_OWNER == signerAddress, "Invalid signature");

        return true;
    }
}
