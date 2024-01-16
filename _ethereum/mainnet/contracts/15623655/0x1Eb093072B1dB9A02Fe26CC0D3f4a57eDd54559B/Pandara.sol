pragma solidity ^0.8.4;


import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

//..........................................................................................
//.PPPPPPPPP.....AAAA.....AAANN...NNNN.NNNDDDDDDD.......AAAA.....AAARRRRRRRR......AAAA......
//.PPPPPPPPPP...AAAAAA....AAANN...NNNN.NNNDDDDDDDD.....AAAAAA....AAARRRRRRRRR....AAAAAA.....
//.PPPPPPPPPPP..AAAAAA....AAANNN..NNNN.NNNDDDDDDDDD....AAAAAA....AAARRRRRRRRR....AAAAAA.....
//.PPPP...PPPP..AAAAAAA...AAANNNN.NNNN.NNND....DDDD....AAAAAAA...AAAR....RRRR....AAAAAAA....
//.PPPP...PPPP.PAAAAAAA...AAANNNN.NNNN.NNND....DDDDD..DAAAAAAA...AAAR....RRRR...RAAAAAAA....
//.PPPPPPPPPPP.PAAAAAAA...AAANNNNNNNNN.NNND.....DDDD..DAAAAAAA...AAARRRRRRRRR...RAAAAAAA....
//.PPPPPPPPPP..PAAA.AAAA..AAANNNNNNNNN.NNND.....DDDD..DAAA.AAAA..AAARRRRRRRR....RAAA.AAAA...
//.PPPPPPPPP..PPAAAAAAAA..AAAN.NNNNNNN.NNND.....DDDD.DDAAAAAAAA..AAARRRRRR.....RRAAAAAAAA...
//.PPPP.......PPAAAAAAAAA.AAAN.NNNNNNN.NNND....DDDDD.DDAAAAAAAAA.AAAR.RRRRR....RRAAAAAAAAA..
//.PPPP......PPPAAAAAAAAA.AAAN..NNNNNN.NNND....DDDD.DDDAAAAAAAAA.AAAR..RRRRR..RRRAAAAAAAAA..
//.PPPP......PPPA....AAAA.AAAN..NNNNNN.NNNDDDDDDDDD.DDDA....AAAA.AAAR...RRRRR.RRRA....AAAA..
//.PPPP......PPPA....AAAAAAAAN...NNNNN.NNNDDDDDDDD..DDDA....AAAAAAAAR....RRRR.RRRA....AAAA..
//.PPPP.....PPPPA.....AAAAAAAN....NNNN.NNNDDDDDDD..DDDDA.....AAAAAAAR.....RRRRRRRA.....AAA..
//..........................................................................................

contract Pandara is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    struct MintConfig {
        uint32 maxPerWlMint;
        uint32 maxPerPublicMint;
        uint64 publicEndTime;
        uint64 wlStartTime;
        uint64 wlEndTime;
    }

    struct PriceConfig {
        uint128 wlPrice;
        uint128 publicPrice;
    }

    uint256 public maxSupply;
    uint256 public maxReserveSupply;
    bytes32 private wlRoot;
    string public contractBaseURI;

    MintConfig public MintParam;
    PriceConfig public price;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        uint256 _wlPrice,
        uint256 _publicPrice,
        uint256 _maxSupply,
        uint256 _maxReserve,
        string memory _contractBaseURI
    ) ERC721A("Pandara", "PNDR") {
        price.wlPrice = uint128(_wlPrice);
        price.publicPrice = uint128(_publicPrice);
        maxSupply = _maxSupply;
        maxReserveSupply = _maxReserve;
        contractBaseURI = _contractBaseURI; 

        MintParam.maxPerWlMint = 10;
        MintParam.maxPerPublicMint = 10;
        MintParam.publicEndTime = uint64(1664992800); 
        MintParam.wlStartTime = uint64(1664366400); 
        MintParam.wlEndTime = uint64(1664388000); 
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /*******************
     * Helper Functions *
     *******************/

    function isWhitelisted(
        bytes32[] calldata _merkleProof,
        bytes32 root,
        address user
    ) private pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "User is not whitelisted"
        );
        return true;
    }

    /*******************
     * Mint Functions *
     *******************/

    function wlMint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        uint256 wlStartTime = uint256(MintParam.wlStartTime);
        uint256 wlEndTime = uint256(MintParam.wlEndTime);
        uint256 wlPrice = uint256(price.wlPrice);
        uint256 maxPerWlMint = uint256(MintParam.maxPerWlMint);

        // Check if Whitelist Mint has started or has ended
        require(
            block.timestamp > wlStartTime,
            "Whitelist Mint has not started!"
        );
        require(block.timestamp < wlEndTime, "Whitelist Mint has ended!");

        // Basic Checks
        require(quantity > 0, "Quantity must be more than 0");
        require(
            (numberMinted(msg.sender) + quantity) <= maxPerWlMint,
            "You cannot mint more than 10 NFTs!"
        );

        require(quantity <= maxPerWlMint, "Quantity exceeds max per WL mint");
        require(
            msg.value == wlPrice * quantity,
            "Strictly As Per Mint Price Required"
        );
        require(
            isWhitelisted(_merkleProof, wlRoot, msg.sender),
            "You are not chosen to mint!"
        );
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        uint256 publicStartTime = uint256(MintParam.wlEndTime);
        uint256 publicEndTime = uint256(MintParam.publicEndTime);
        uint256 publicPrice = uint256(price.publicPrice);
        uint256 maxPerPublicMint = uint256(MintParam.maxPerPublicMint);

        // Check if Public Mint has started or has ended
        require(
            block.timestamp > publicStartTime,
            "Public Mint has not started!"
        );
        require(block.timestamp < publicEndTime, "Public Mint has ended!");

        // Basic Checks
        require(quantity > 0, "Quantity must be more than 0");
        require(
            (numberMinted(msg.sender) + quantity) <= maxPerPublicMint,
            "You cannot mint more than 10 NFTs!"
        );
        require(
            quantity <= maxPerPublicMint,
            "Quantity exceeds max per Public mint"
        );
        require(
            msg.value == publicPrice * quantity,
            "Strictly As Per Mint Price Required"
        );

        _safeMint(msg.sender, quantity);
    }

    /*******************
     * Owner Functions *
     *******************/

    // Team Supply Mint of 300
    function reserveNFTs(address to, uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        require(quantity > 0, "Quantity cannot be zero");
        uint256 totalMinted = totalSupply();
        require(
            totalMinted.add(quantity) <= maxReserveSupply,
            "All 300 Team Supply Minted"
        );
        _safeMint(to, quantity);
    }

    // Reveal
    function setBaseUri(string memory _URI) external onlyOwner nonReentrant {
        contractBaseURI = _URI;
    }

    // Set Whitelist Root
    function setWlRoot(bytes32 _root) external onlyOwner nonReentrant {
        wlRoot = _root;
    }

    // Set Mint Timing
    function setMintTiming(
        uint256 _wlStartTime,
        uint256 _wlEndTime,
        uint256 _publicEndTime
    ) external onlyOwner nonReentrant {
        MintParam.wlStartTime = uint64(_wlStartTime);
        MintParam.wlEndTime = uint64(_wlEndTime);
        MintParam.publicEndTime = uint64(_publicEndTime);
    }

    // Refund if the value sent is more than the required amount
    function refundIfOver(uint256 cost) private {
        require(msg.value >= cost, "Need to send more ETH.");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    function unpause() external onlyOwner nonReentrant {
        _unpause();
    }

    // Fund Withdrawal to the Owner
    function withdrawToContract() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
    }

    // Fund Withdrawal Split
    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 fundBalance = address(this).balance;
        (bool success, ) = (0xb3da8C447F979100A3F05549Adb507f2A526319a).call{value: 4 * (fundBalance / 10)}(""); //! 40% of Funds goes to the 0xb3da8C447F979100A3F05549Adb507f2A526319a
        (bool success2, ) = (0xa3f5d48b0Cb7E39D1747C7a253E9C5B5f92e371B).call{value: 2 * (fundBalance / 10)}(""); //! 20% of Funds goes to the 0xa3f5d48b0Cb7E39D1747C7a253E9C5B5f92e371B
        (bool success3, ) = (0xD87f9f18577fB6cA28518E27E43F6D0215CFDEAB).call{value: 2 * (fundBalance / 10)}(""); //! 20% of Funds goes to the 0xD87f9f18577fB6cA28518E27E43F6D0215CFDEAB
        (bool success4, ) = (0x0beAd4FDdf82C0F0cd121C0c230cCcB1FEE87C71).call{value: 2 * (fundBalance / 10)}(""); //! 20% of Funds goes to the 0x0beAd4FDdf82C0F0cd121C0c230cCcB1FEE87C71
        require(success, "Transfer to 0xb3da8C447F979100A3F05549Adb507f2A526319a failed.");
        require(success2, "Transfer to 0xa3f5d48b0Cb7E39D1747C7a253E9C5B5f92e371B failed.");
        require(success3, "Transfer to 0xD87f9f18577fB6cA28518E27E43F6D0215CFDEAB failed.");
        require(success4, "Transfer to 0x0beAd4FDdf82C0F0cd121C0c230cCcB1FEE87C71 failed.");
    }

    /*******************
     * Getter Functions *
     *******************/
    function _baseURI() internal view virtual override returns (string memory) {
        return contractBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}
