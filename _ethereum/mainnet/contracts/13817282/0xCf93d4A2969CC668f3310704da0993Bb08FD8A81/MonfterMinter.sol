// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

import "./MonfterNFT.sol";

contract MonfterMinter is Context, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 public monToken;
    MonfterNFT public monfterNft;
    address payable public wallet;
    IERC721 public BAYC;
    IERC721 public doodles;

    // base mint price
    uint256 public preMintPrice = 0.02 ether;
    uint256 public pubMintPrice = 0.06 ether;

    uint256 public preMintLimitDate;
    uint256 public preMintDate;

    uint256 public MAX_PRE_TRANS = 10;
    uint256 public PRE_MAX_PER_ADDRESS = 10;
    uint256 public MIN_MON_HOLD = 50000e18;
    uint256 public MAX_PRE_MINT = 500;
    uint256 public MAX_PUB_MINT = 6000;

    uint256 public whitelistMint;
    uint256 public monHolderMint;
    uint256 public nftHolderMint;
    uint256 public earlyTraderMint;

    // mint account for address
    mapping(address => uint256) public whitelistMintLog;
    mapping(address => uint256) public nftMintLog;
    mapping(address => uint256) public tokenMintLog;
    mapping(address => uint256) public traderMintLog;

    bytes32 public communityMerkleRoot;
    bytes32 public traderMerkleRoot;

    bool public pubMintState;
    bool public traderMintState;
    Counters.Counter public pubMintCounter;

    event Mint(address indexed account, uint256 amount);

    enum Role {
        communityMember,
        monHolder,
        nftHolder,
        earlyTrader
    }

    constructor(
        IERC20 _monToken,
        MonfterNFT _monfterNft,
        address payable _wallet,
        IERC721 _BAYC,
        IERC721 _doodles
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        monToken = _monToken;
        monfterNft = _monfterNft;
        wallet = _wallet;
        BAYC = _BAYC;
        doodles = _doodles;
        pubMintState = false;
        traderMintState = false;
        preMintLimitDate = block.timestamp + 3 days;
        preMintDate = block.timestamp + 7 days;
    }

    modifier onlyStartPubMint() {
        require(pubMintState, "MonfterMinter: pub mint not start");
        _;
    }

    modifier onlyBetweenPreMint() {
        require(block.timestamp <= preMintDate, "MonfterMinter: pre mint end");
        _;
    }
    modifier onlyTraderMint() {
        require(traderMintState, "MonfterMinter: trader mint not start");
        _;
    }

    function setPubMintState(bool state) public onlyRole(DEFAULT_ADMIN_ROLE) {
        pubMintState = state;
    }

    function setTraderMintState(bool state)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        traderMintState = state;
    }

    function setCommunityMerkleRoot(bytes32 _merkleRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        communityMerkleRoot = _merkleRoot;
    }

    function setTraderMerkleRoot(bytes32 _merkleRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        traderMerkleRoot = _merkleRoot;
    }

    function beforePreMint(
        Role role,
        uint256 amount,
        bytes32[] memory proof
    ) internal view {
        require(amount <= MAX_PRE_TRANS, "MonfterMinter: invalid amount");
        if (role == Role.communityMember) {
            require(
                whitelistMint.add(amount) <= MAX_PRE_MINT,
                "MonfterMinter: invalid amount"
            );
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProof.verify(proof, communityMerkleRoot, node),
                "MerkleDistributor: Invalid proof."
            );

            if (block.timestamp < preMintLimitDate) {
                require(
                    whitelistMintLog[_msgSender()].add(amount) <= 1,
                    "MonfterMinter: already mint or invalid amount"
                );
            }
        } else if (role == Role.monHolder) {
            require(
                monToken.balanceOf(_msgSender()) >= MIN_MON_HOLD,
                "MonfterMinter: invalid monfter token amount"
            );
            require(
                monHolderMint.add(amount) <= MAX_PRE_MINT,
                "MonfterMinter: invalid amount"
            );

            if (block.timestamp < preMintLimitDate) {
                require(
                    tokenMintLog[_msgSender()].add(amount) <=
                        PRE_MAX_PER_ADDRESS,
                    "MonfterMinter: already mint or invalid amount"
                );
            }
        } else if (role == Role.nftHolder) {
            require(
                nftHolderMint.add(amount) <= MAX_PRE_MINT,
                "MonfterMinter: invalid amount"
            );
            require(
                BAYC.balanceOf(_msgSender()) >= 1 ||
                    doodles.balanceOf(_msgSender()) >= 1,
                "MonfterMinter: invalid nft amount"
            );

            if (block.timestamp < preMintLimitDate) {
                require(
                    nftMintLog[_msgSender()].add(amount) <= PRE_MAX_PER_ADDRESS,
                    "MonfterMinter: already mint or invalid amount"
                );
            }
        } else if (role == Role.earlyTrader) {
            require(
                earlyTraderMint.add(amount) <= MAX_PRE_MINT &&
                    traderMintLog[_msgSender()].add(amount) <= 1,
                "MonfterMinter: invalid amount"
            );
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProof.verify(proof, traderMerkleRoot, node),
                "MonfterMinter: invalid proof."
            );
        } else {
            require(false, "MonfterMinter: invalid role");
        }
    }

    function afterPreMint(Role role, uint256 amount) internal {
        if (role == Role.communityMember) {
            whitelistMint = whitelistMint.add(amount);
            whitelistMintLog[_msgSender()] += amount;
        } else if (role == Role.monHolder) {
            monHolderMint = monHolderMint.add(amount);
            tokenMintLog[_msgSender()] += amount;
        } else if (role == Role.nftHolder) {
            nftHolderMint = nftHolderMint.add(amount);
            nftMintLog[_msgSender()] += amount;
        } else if (role == Role.earlyTrader) {
            earlyTraderMint = earlyTraderMint.add(amount);
            traderMintLog[_msgSender()] += amount;
        } else {
            require(false, "MonfterMinter: invalid role");
        }
    }

    function preMintLeft() public view returns (uint256) {
        return
            MAX_PRE_MINT.mul(3).sub(whitelistMint).sub(monHolderMint).sub(
                nftHolderMint
            );
    }

    function preMint(
        uint256 role,
        uint256 amount,
        bytes32[] calldata proof
    ) public payable nonReentrant onlyBetweenPreMint {
        uint256 weiAmount = msg.value;
        require(
            weiAmount >= preMintPrice.mul(amount),
            "MonfterMinter: invalid price"
        );

        beforePreMint(Role(role), amount, proof);

        // transfer
        wallet.transfer(weiAmount);

        // mint
        for (uint256 i = 0; i < amount; i++) {
            monfterNft.safeMint(_msgSender());
        }

        afterPreMint(Role(role), amount);

        emit Mint(_msgSender(), amount);
    }

    function pubMint(uint256 amount)
        public
        payable
        nonReentrant
        onlyStartPubMint
    {
        uint256 weiAmount = msg.value;
        require(
            weiAmount >= pubMintPrice.mul(amount),
            "MonfterMinter: invalid price"
        );
        require(amount <= PRE_MAX_PER_ADDRESS, "MonfterMinter: invalid amount");
        require(
            pubMintCounter.current() < MAX_PUB_MINT.add(preMintLeft()),
            "MonfterMinter: invalid amount"
        );

        // transfer
        wallet.transfer(weiAmount);

        for (uint256 i = 0; i < amount; i++) {
            monfterNft.safeMint(_msgSender());
        }

        pubMintCounter.increment();

        emit Mint(_msgSender(), amount);
    }

    function traderMint(uint256 amount, bytes32[] calldata proof)
        public
        payable
        nonReentrant
        onlyTraderMint
    {
        uint256 weiAmount = msg.value;
        require(
            weiAmount >= preMintPrice.mul(amount),
            "MonfterMinter: invalid price"
        );

        beforePreMint(Role.earlyTrader, amount, proof);

        // transfer
        wallet.transfer(weiAmount);

        // mint
        for (uint256 i = 0; i < amount; i++) {
            monfterNft.safeMint(_msgSender());
        }

        afterPreMint(Role.earlyTrader, amount);

        emit Mint(_msgSender(), amount);
    }
}
