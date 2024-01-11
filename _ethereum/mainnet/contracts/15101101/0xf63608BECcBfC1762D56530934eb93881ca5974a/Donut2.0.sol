// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ERC2981.sol";
import "./ECDSA.sol";

interface IDONUT10 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function burn(uint256 tokenId) external;
}

contract NavyGDonut is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string public baseURI = "";
    string public notRevealedURI= "https://ipfs.donutnomads.art/2.0/bonut_blind2.0.json";

    bool public started = false;
    bool public revealed = false;

    uint256 public maxSupplyAmount = 2222;
    address public signer;
    address public Donut10;
    bool public needAuth = true;

    constructor(
        address _signer,
        address _donut10
    ) ERC721A("Navy GnDonut", "NGD") {
        signer = _signer;
        Donut10 = _donut10;
        setFeeNumerator(800);
    }

    function compound(address who, string memory who_str, uint256 [] memory tokenIds, bytes memory signature) external {
        require(started, "Sale is not started");
        require(totalSupply() < maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");

        if (tokenIds.length == 4) {
            // pass
        } else if (tokenIds.length == 3 || tokenIds.length == 2){
            address tmpSigner = getSigner(who_str, tokenIds, signature);
            require(!needAuth || signer == tmpSigner, "Not authorized to compound");
        } else {
            revert("ERROR: Params InComplete");
        }

        for (uint i=0; i<tokenIds.length; i++) {
            require(IDONUT10(Donut10).ownerOf(tokenIds[i]) == who, "");
            IDONUT10(Donut10).burn(tokenIds[i]);
        }

        _safeMint(who, 1);
    }

    function burn(uint256 tokenId) external{
        _burn(tokenId, true);
        
    }

    /********************************* view ********************************/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedURI;
        }
        
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    struct Status {
        uint256 maxSupply;
        uint32 userMinted;
        bool soldout;
        bool started;
    }

    function status(address minter) external view returns (Status memory) {
        return Status({
            maxSupply: maxSupplyAmount,

            userMinted: uint32(_numberMinted(minter)),
            soldout: totalSupply() >= maxSupplyAmount,
            started: started
        });
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /************************************* onlyOwner ********************/
    function devmint(address to, uint32 amount) external onlyOwner {
        require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
        _safeMint(to, amount);
    }

    function multidevmint(address [] calldata tos, uint32 [] calldata amounts) external onlyOwner {
        require(tos.length == amounts.length, "tos length must eq amounts");
        for(uint l = 0; l < tos.length; l ++) {
            require(amounts[l] + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
            _safeMint(tos[l], amounts[l]);
        }
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setNotRevealedURI(string memory newURI)external onlyOwner {
        notRevealedURI = newURI;
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool _started) external onlyOwner {
        started = _started;
    }

    function setMaxSupply(uint32 _newValue) external onlyOwner {
        maxSupplyAmount = _newValue;
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function toggleAuth() external onlyOwner {
        needAuth = !needAuth;
    }

    /************************************* internal ********************/
    function signatureWallet (bytes memory context, bytes memory signature) private pure returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(context)
            )
        );
        return ECDSA.recover(hash, signature);
    }

    function getSigner(string memory who, uint256 [] memory tokenIds, bytes memory signature) private pure returns(address ret) {
        if (tokenIds.length == 3){
            bytes memory sign_context = abi.encodePacked(who, tokenIds[0], tokenIds[1], tokenIds[2]);
            ret = signatureWallet(sign_context, signature);
        } else if (tokenIds.length == 2){
            bytes memory sign_context = abi.encodePacked(who, tokenIds[0], tokenIds[1]);
            ret = signatureWallet(sign_context, signature);
        }else if (tokenIds.length == 0) {
            bytes memory sign_context = abi.encodePacked(who);
            ret = signatureWallet(sign_context, signature);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}

// 0xAfecCABA00fAfb6596047a08e7Ff0d5fe40d2bf2
// 0xd6723858acda8d684d5dd1eca18a89c441716926