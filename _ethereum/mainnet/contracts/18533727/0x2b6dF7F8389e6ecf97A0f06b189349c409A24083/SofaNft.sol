// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IRevealed721NFT.sol";

import "./Auction.sol";

contract SofaNFT is Ownable, ERC721AQueryable, ReentrancyGuard, AuctionMintContract {
    constructor() ERC721A("Sofa Maker", "Sofa Maker") {
        _safeMint(owner(), 1);
    }

    string public BASE_URI = "ipfs://bafybeiei3tgirxccl4sgoq4b5xkzquropmgzucy3w3pz5wmgs5pprf5o2q/";

    mapping(uint256 => uint256) private claimedBitMap;
    bytes32 public merkleRoot;

    function initialize() public onlyOwner nonReentrant {}

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant WL1_SUPPLY = 2000;

    uint256 public constant WL1_MAX_MINT = 3;
    uint256 public constant WL_MAX_MINT = 3;
    uint256 public constant PUBLIC_MAX_MINT = 3;

    uint256 public wl1Minted = 0;
    uint256 public wl2Minted = 0;
    uint256 public publicMinted = 0;

    bool public paused = false; // if the saling is running
    uint256 public minted = 0;
    uint256 public PUBLIC_PRICE = 0.0169 ether;

    mapping(address => mapping(uint256 => uint256)) public userStageMinted;
    mapping(address => uint256) public userMinted; // to limit single user mint max
    mapping(address => bool) public burnPassMap;

    mapping(uint256 => uint256) public timeRanges; // the ranges of start and end

    function setBaseUri(string memory uri) public onlyOwner {
        BASE_URI = uri;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        PUBLIC_PRICE = newPrice;
    }

    function setTimeRanges(uint256[] calldata ranges) public onlyOwner {
        for (uint8 i = 0; i < ranges.length; i++) {
            timeRanges[i] = ranges[i];
        }
    }

    function checkRange(uint256 index) public {
        require(block.timestamp >= timeRanges[index * 2], "stage not start");
        require(block.timestamp <= timeRanges[index * 2 + 1], "stage already finished");
    }

    modifier notPaused() {
        require(!paused, "error: sale paused!");
        _;
    }

    function wlPrice() public view returns (uint256) {
        // if (finalAuctionPrice == 0) return 0;
        // if auction soldout, check
        if (auctionSoldout && finalAuctionPrice != auctionPriceList[auctionStepList.length - 1]) {
            return (finalAuctionPrice * 800) / 1000;
        }
        return 0.0119 ether;
    }

    function whitelist1Mint(
        uint256 amount,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        require(wallet == account, "error: u are not the real WL owner!");
        // check time range
        checkRange(0);
        // EOA check
        require(msg.sender == tx.origin, "error: eoa only");
        // CHECK PAYMENT
        require(wlPrice() * amount <= msg.value, "error: price not enough");
        // CHECK REACH USER MINT CAP
        require(
            userStageMinted[wallet][1] + amount <= WL1_MAX_MINT,
            "error: whitelist cannot mint more than MAX_MINT (1) !"
        );
        require(wl1Minted + amount <= WL1_SUPPLY, "error: current stage mint finished");
        // 7. verify merkle proof
        bool claimed = merkleVerifyAndSetClaimed(index, 1, account, merkleProof);
        _safeMint(wallet, amount);
        userStageMinted[wallet][1] += amount;
        wl1Minted += amount;
    }

    function whitelistMint(
        uint256 amount,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        require(wallet == account, "error: u are not the real WL owner!");
        // check time range
        checkRange(1);
        // EOA check
        require(msg.sender == tx.origin, "error: eoa only");
        // CHECK PAYMENT
        require(wlPrice() * amount <= msg.value, "error: price not enough");
        // CHECK REACH USER MINT CAP
        require(
            userStageMinted[wallet][2] + amount <= WL_MAX_MINT,
            "error: whitelist cannot mint more than MAX_MINT (2) !"
        );
        // require(wl2Minted + amount <= WL2_SUPPLY(), "error: current stage mint finished");
        // CHECK REACH CAP
        require(MAX_SUPPLY >= minted + amount, "error: MAX_SUPPLY reached!");
        // 7. verify merkle proof
        bool claimed = merkleVerifyAndSetClaimed(index, 2, account, merkleProof);
        _safeMint(wallet, amount);
        userStageMinted[wallet][2] += amount;
        wl2Minted += amount;
    }

    // auction user mint
    function auctionMint(uint256 amount) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        // EOA check
        require(msg.sender == tx.origin, "error: eoa only");
        // precheck and set state
        auctionBeforeMint(wallet, amount, msg.value);
        // just mint
        _safeMint(wallet, amount);
    }

    function WL2_SUPPLY() public view returns (uint256) {
        return MAX_SUPPLY - auctionData.minted - wl1Minted;
    }

    function publicSupply() public view returns (uint256) {
        return MAX_SUPPLY - auctionData.minted - wl1Minted - wl2Minted;
    }

    function publicMint(uint256 amount) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        // EOA check
        require(msg.sender == tx.origin, "error: eoa only");
        // check time range
        checkRange(2);
        // CHECK PAYMENT
        require(wlPrice() * amount <= msg.value, "error: price not enough");
        // CHECK REACH CAP
        require(MAX_SUPPLY >= minted + amount, "error: MAX_SUPPLY reached!");
        // CHECK REACH USER MINT CAP
        require(
            PUBLIC_MAX_MINT >= userStageMinted[wallet][3] + amount,
            "error: u cannot mint more than PUBLIC_MAX_MINT(2) !"
        );
        _safeMint(wallet, amount);
        publicMinted += amount;
        userStageMinted[wallet][3] += amount;
    }

    /// rertieve if the nth tree's index has claimed
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// set the exact pool's index was claimed
    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // only for dev time
    function verify(
        bytes32 _merkleRoot,
        uint256 index,
        address account,
        uint256 stage,
        bytes32[] calldata merkleProof
    ) public pure returns (bool) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, stage));
        return MerkleProof.verify(merkleProof, _merkleRoot, node);
    }

    /**
     * @notice  user claim using merkle proof, providing info to the contract
                be sure，u must ensure that the account is verified to be the sender!
     * @dev
     * @param   index   the tree leaf index
     * @param   stage   identify which stage this address in
     * @param   account the user address, ofcourse, it shall be the msg.sender
     * @param   merkleProof  the tree generated proof data
     */
    function merkleVerifyAndSetClaimed(
        uint256 index,
        uint256 stage,
        address account,
        bytes32[] calldata merkleProof
    ) internal returns (bool claimed) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, stage));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");
        claimed = isClaimed(index);

        // Mark it claimed and send the token.
        if (!claimed) {
            _setClaimed(index);
        }
    }

    function _safeMint(address wallet, uint256 amount) internal override {
        // mint
        super._safeMint(wallet, amount);
        userMinted[wallet] += amount;
        minted += amount;
    }

    function setBurnPassMap(address _addr, bool pass) public onlyOwner {
        burnPassMap[_addr] = pass;
    }

    function burn(uint256 tokenId, address _user) external {
        require(_msgSender() == owner() || burnPassMap[_msgSender()], "error:user or contract shall not pass");
        require(ownerOf(tokenId) == _user, "error:only owner can burn this token!");
        _burn(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) {
        super.approve(operator, tokenId);
    }

    struct ContractDashboard {
        bool paused;
        uint256 maxSupply;
        uint256 totalMinted;
        uint256 totalSupply;
        uint256 currentStage;
        // auction
        uint256 price_auction;
        uint256 minted_auction;
        uint256 supply_auction;
        uint256 user_minted_auction;
        // auctionConf
        uint256[] auction_price_list;
        uint256[] auction_time_list;
        uint256[] auction_supply_list;
        // wl_1
        uint256 price;
        uint256 minted_wl_1;
        uint256 supply_wl_1;
        uint256 user_minted_wl_1;
        // wl_2
        uint256 minted_wl_2;
        uint256 supply_wl_2;
        uint256 user_minted_wl_2;
        // public
        uint256 minted_public;
        uint256 supply_public;
        uint256 user_minted_public;
        // time
        uint256 auctionStart;
        uint256 auctionEnd;
        uint256 wl1Start;
        uint256 wl1End;
        uint256 wl2Start;
        uint256 wl2End;
        uint256 publicStart;
        uint256 publicEnd;
        uint256 now;
        uint256 userCurrentMinted;
        uint256 currentRoundUserMax;
        bool auctionSoldout;
    }

    function status(address _addr, uint256 now) public view returns (ContractDashboard memory dashboard) {
        dashboard.paused = paused;
        dashboard.maxSupply = MAX_SUPPLY;
        dashboard.totalMinted = minted;
        dashboard.totalSupply = totalSupply();
        (uint256 auctionPrice, uint256 auctionSupply) = currentPriceAndSupply(block.timestamp);
        dashboard.price_auction = auctionPrice;
        dashboard.minted_auction = auctionData.minted;
        dashboard.supply_auction = auctionSupply;
        dashboard.user_minted_auction = auctionMinted[_addr];

        dashboard.auction_price_list = new uint256[](auctionStepList.length);
        dashboard.auction_time_list = new uint256[](auctionStepList.length);
        dashboard.auction_supply_list = new uint256[](auctionStepList.length);
        for (uint i = 0; i < auctionStepList.length; i++) {
            dashboard.auction_price_list[i] = auctionPriceList[i];
            dashboard.auction_time_list[i] = auctionStepList[i];
            dashboard.auction_supply_list[i] = auctionSupplyList[i];
        }

        dashboard.price = wlPrice();
        dashboard.minted_wl_1 = wl1Minted;
        dashboard.supply_wl_1 = WL1_SUPPLY;
        dashboard.user_minted_wl_1 = userStageMinted[_addr][1];

        dashboard.minted_wl_2 = wl2Minted;
        dashboard.supply_wl_2 = WL2_SUPPLY();
        dashboard.user_minted_wl_2 = userStageMinted[_addr][2];

        dashboard.minted_public = publicMinted;
        dashboard.supply_public = publicSupply();
        dashboard.user_minted_public = userStageMinted[_addr][3];

        dashboard.auctionStart = auctionData.startTimestamp;
        dashboard.auctionEnd = auctionData.finishTimestamp;

        dashboard.wl1Start = timeRanges[0];
        dashboard.wl1End = timeRanges[1];
        dashboard.wl2Start = timeRanges[2];
        dashboard.wl2End = timeRanges[3];
        dashboard.publicStart = timeRanges[4];
        dashboard.publicEnd = timeRanges[5];
        dashboard.now = block.timestamp + 0;
        dashboard.auctionSoldout = auctionSoldout;

        if (block.timestamp < dashboard.auctionStart) {
            dashboard.currentStage = 101;
        } else if (block.timestamp < dashboard.auctionEnd && !auctionSoldout) {
            dashboard.currentStage = 1;
            dashboard.userCurrentMinted = dashboard.user_minted_auction;
            dashboard.currentRoundUserMax = auctionData.maxBuy;
        } else if (block.timestamp < dashboard.auctionEnd && auctionSoldout) {
            // auction stoped
            dashboard.currentStage = 102;
            dashboard.userCurrentMinted = dashboard.user_minted_auction;
            dashboard.currentRoundUserMax = auctionData.maxBuy;
        } else if (block.timestamp < dashboard.wl1Start) {
            dashboard.currentStage = 102;
            dashboard.userCurrentMinted = dashboard.user_minted_auction;
            dashboard.currentRoundUserMax = auctionData.maxBuy;
        } else if (block.timestamp < dashboard.wl1End) {
            dashboard.currentStage = 2;
            dashboard.userCurrentMinted = dashboard.user_minted_wl_1;
            dashboard.currentRoundUserMax = WL1_MAX_MINT;
        } else if (block.timestamp < dashboard.wl2Start) {
            dashboard.currentStage = 103;
            dashboard.userCurrentMinted = dashboard.user_minted_wl_1;
            dashboard.currentRoundUserMax = WL1_MAX_MINT;
        } else if (block.timestamp < dashboard.wl2End) {
            dashboard.currentStage = 3;
            dashboard.userCurrentMinted = dashboard.user_minted_wl_2;
            dashboard.currentRoundUserMax = WL_MAX_MINT;
        } else if (block.timestamp < dashboard.publicStart) {
            dashboard.currentStage = 104;
            dashboard.userCurrentMinted = dashboard.user_minted_wl_2;
            dashboard.currentRoundUserMax = WL_MAX_MINT;
        } else if (block.timestamp < dashboard.publicEnd) {
            dashboard.currentStage = 4;
            dashboard.userCurrentMinted = dashboard.user_minted_public;
            dashboard.currentRoundUserMax = PUBLIC_MAX_MINT;
        } else {
            dashboard.currentStage = 105;
            dashboard.userCurrentMinted = dashboard.user_minted_public;
            dashboard.currentRoundUserMax = PUBLIC_MAX_MINT;
        }

        return dashboard;
    }

    IRevealed721NFT revealedContract;

    function setRevealContract(address addr) public onlyOwner {
        revealedContract = IRevealed721NFT(addr);
    }

    function reveal(uint256[] calldata tokenIdList) public {
        require(isAllowTransfer, "reveal not begin");
        require(_msgSender() == tx.origin, "error: eoa only");
        for (uint i = 0; i < tokenIdList.length; i++) {
            uint256 tokenId = tokenIdList[i];
            require(ownerOf(tokenId) == _msgSender(), "only owner can reveal");
            revealedContract.revealMint(_msgSender(), tokenId);
            _burn(tokenId);
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) {
        assertAllowTransfer(from, to);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) {
        assertAllowTransfer(from, to);
        super.safeTransferFrom(from, to, tokenId);
    }

    bool private isAllowTransfer = false;

    function setAllowTransfer(bool _isAllow) public onlyOwner {
        isAllowTransfer = _isAllow;
    }

    function assertAllowTransfer(address from, address to) internal view {
        if (!isAllowTransfer) {
            require(from == address(0), "transfer reach limit");
        }
    }

    function mintTreasure(uint256 _amount,uint256 stage) public onlyOwner {
        uint256 amount = _amount;
        if(stage == 1) {
            require(auctionRunning(),"sorry auction not running");
            
            (uint256 newPrice, uint256 newSupply) = currentPriceAndSupply(block.timestamp);
            finalAuctionPrice = newPrice;
            // reach cap
            if (auctionData.minted + amount >= newSupply) {
                amount = newSupply - auctionData.minted;
                auctionData.minted = newSupply;
                auctionSoldout = true;
            } else {
                // not reach cap
                auctionData.minted += amount;
            }
        }
        if(stage == 2) {
            checkRange(0);
            if(wl1Minted + amount > WL1_SUPPLY) {
                amount = WL1_SUPPLY - wl1Minted;   
            }
            wl1Minted += amount;
        }
        if(stage == 3) {
            checkRange(1);
            wl2Minted += amount;
        }
        if(stage == 4) {
            checkRange(2);
            publicMinted += amount;
        }
        require(MAX_SUPPLY >= minted + amount, "error: MAX_SUPPLY reached!");
        _safeMint(owner(), amount);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) {
        assertAllowTransfer(from, to);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        return ERC721A.supportsInterface(interfaceId);
    }

    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        uint256 _amt = amount;
        if (amount == 0) {
            _amt = address(this).balance;
        }
        require(_amt > 0, "error:amount cannot be zero");
        _widthdraw(owner(), _amt);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "error:Transfer failed.");
    }
}
