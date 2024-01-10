//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

/*-------------------------------------------------------------------------------------------]
  _________.__          __  .__       __      __                     .__
 /   _____/|  |   _____/  |_|  |__   /  \    /  \_____ ______________|__| ___________  ______
 \_____  \ |  |  /  _ \   __\  |  \  \   \/\/   /\__  \\_  __ \_  __ \  |/  _ \_  __ \/  ___/
 /        \|  |_(  <_> )  | |   Y  \  \        /  / __ \|  | \/|  | \/  (  <_> )  | \/\___ \
/_______  /|____/\____/|__| |___|  /   \__/\  /  (____  /__|   |__|  |__|\____/|__|  /____  >
        \/                       \/         \/        \/                                  \/
---------------------------------------------------------------------------------------------]*/
contract SlothWarrior is ERC721A, Ownable {

    using ECDSA for bytes32;

    mapping(uint => string) public PROVENANCE;

    enum SalePhase {
        Locked,
        PreSale,
        PublicSale
    }

    SalePhase public phase = SalePhase.Locked;

    uint public battlePack = 1;
    uint256 public presalePrice = 0.04 ether;
    uint256 public publicPrice = 0.06 ether;
    uint256 public maxWarriors = 3333;

    uint public constant MAX_PRESALE_MINT = 2;
    uint public constant MAX_PUBLIC_MINT = 10;

    string private baseURI = "https://api.slothwarriors.com/tokens/";

    address private _signerAddress;
    mapping(address => uint) public tokensMinted;

    constructor(
        address signerAddress_,
        uint256 max
    ) ERC721A("Sloth Warriors", "SLOWAR") {
        _signerAddress = signerAddress_;
        maxWarriors = max;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE[battlePack] = provenance;
        battlePack++;
    }

    // Mints for promotional purposes and founding team/investors
    function reserveMint() public onlyOwner {
        require(totalSupply() == 0, 'PROMO_RUN');
        _safeMint(0x96B0AdfFb0A4dc97166ffaC92899927D5034e095, 50);
    }

    function presaleMint(uint256 numTokens, bytes calldata signature) public payable {
        require(phase == SalePhase.PreSale, 'Presale is not active');
        require(msg.value == numTokens * presalePrice, 'Incorrect ether amount');
        require(MAX_PRESALE_MINT >= tokensMinted[msg.sender] + numTokens, "Claim limit exceeded.");
        require(totalSupply() + numTokens <= maxWarriors, 'MAX_REACHED');

        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Signer address mismatch.");

        tokensMinted[msg.sender] += numTokens;

        _safeMint(msg.sender, numTokens);
    }

    function publicMint(uint256 numTokens) public payable {
        require(phase == SalePhase.PublicSale, 'Public sale is not active');
        require(msg.value == numTokens * publicPrice, 'Incorrect ether amount');
        require(numTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase per transaction");
        require(totalSupply() + numTokens <= maxWarriors, 'MAX_REACHED');
        _safeMint(msg.sender, numTokens);
    }

    function setPhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    function setPresalePrice(uint256 newPrice) public onlyOwner {
        presalePrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMax(uint256 _max) public onlyOwner {
        require(_max > maxWarriors, 'TOO_LOW');
        maxWarriors = _max;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.slothwarriors.com/contract-meta";
    }
}
