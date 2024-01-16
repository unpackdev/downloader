// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

interface CCCFactory {
    function mint(address) external;
}

interface CCCPass {
    function claimedCount(address) external view returns (uint256);
    function claimPass(
        address sender,
        uint256 _passAmount,
        uint256 _amountToMint,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external;
}

contract CCCStore is Ownable, VRFConsumerBase {
    CCCPass public cccPass;
    CCCFactory public cccFactory;

    /**
        Max supply
     */
    uint256 public constant maxCCC = 5000;

    /**
        Verification and VRF
     */
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public shuffleNumber;
    string public constant verificationHash = "cac4549537bc6847f748479b916677fc29948e8240f94fd73020dd7dd0ffab49"; // hash to verify initial order. it will be the keccak256 hash of the ipfs hash

    /**
        Team allocated CCC
     */
    uint256 public constant maxCCCForTeam = 345; // 6.9% of 5000

    /**
        Mint stats
     */
    uint256 public totalCCCMinted = 0;
    uint256 public totalCCCMintedByTeam = 0;
    uint256 public totalCCCMintedByVIP = 0;
    mapping(address => uint256) public CCCMinted;
    uint256 public totalETHDonated = 0;
    uint256 public totalETHDonatedByVIP = 0;

    /**
        Scheduling
     */
    uint256 public openingHours = 1665411010; // 2022-10-10 22:10:10 GMT+8

    /**
        Prices
     */
    uint256 public mintPrice = 0.2 ether;
    uint256 public constant VIPDiscount = 0.05 ether;

    /**
        Security
     */
    uint256 public constant maxMintPerTx = 100;

    event SetCCCPass(address cccPass);
    event SetCCCFactory(address cccFactory);
    event SetMintPrice(uint256 price);
    event SetOpeningHours(uint256 openingHours);
    event MintCCC(address account, uint256 amount);
    event Withdraw(address to);

    // mainnet
    // constructor()
    //     VRFConsumerBase(
    //         0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
    //         0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    //     ) {
    //     keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    //     fee = 2 * 10 ** 18;
    // }

    // goerli
    constructor()
        VRFConsumerBase(
            0x2bce784e69d2Ff36c71edcB9F88358dB0DfB55b4, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ) {
        keyHash = 0x0476f9a745b61ea5c0ab224d3a6e4c99f0b02fce4da01143a4f70aa80ae76e8a;
        fee = 0.1 * 10 ** 18;
    }

    modifier whenOpened() {
        require(
            block.timestamp >= openingHours,
            "Store is not opened"
        );
        _;
    }

    function setCCCPass(CCCPass _cccPass) external onlyOwner {
        cccPass = _cccPass;
        emit SetCCCPass(address(_cccPass));
    }

    function setCCCFactory(CCCFactory _cccFactory) external onlyOwner {
        cccFactory = _cccFactory;
        emit SetCCCFactory(address(_cccFactory));
    }

    // price in terms of 0.01 ether
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price * 0.01 ether;
        require(mintPrice >= VIPDiscount, "mintPrice lower than VIPDiscount");
        emit SetMintPrice(_price);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function preMintCCC() external onlyOwner {
        require(totalCCCMintedByTeam == 0, "preMint was done");
        for (uint256 i = 0; i < maxCCCForTeam; i++) {
            cccFactory.mint(msg.sender);
        }
        totalCCCMintedByTeam += maxCCCForTeam;
        totalCCCMinted += maxCCCForTeam;
        CCCMinted[msg.sender] += maxCCCForTeam;
    }

    function mintCCC(
        uint256 _passAmount,
        uint256 _amountToMint,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig)
        external 
        payable 
        whenOpened {
        require(_amountToMint <= maxMintPerTx, "mint amount exceeds maximum");
        require(_amountToMint > 0, "Need to mint more than 0");

        uint256 toClaim = 0;
        if (_passAmount > 0) {
            uint256 senderClaimedCount = cccPass.claimedCount(msg.sender);
            if (_passAmount > senderClaimedCount) {
                uint256 senderUnclaimedCount = _passAmount - senderClaimedCount;
                toClaim = _amountToMint > senderUnclaimedCount ? senderUnclaimedCount : _amountToMint;
                // claimPass will revert if fail
                cccPass.claimPass(msg.sender, _passAmount, toClaim, vSig, rSig, sSig);
            }
        }

        uint256 totalPrice = mintPrice * _amountToMint - VIPDiscount * toClaim;
        require(totalPrice <= msg.value, "Not enough money");

        for (uint256 i = 0; i < _amountToMint; i += 1) {
            cccFactory.mint(msg.sender);
        }

        totalCCCMinted += _amountToMint;
        CCCMinted[msg.sender] += _amountToMint;
        totalETHDonated += totalPrice;
        if (_passAmount > 0) {
            totalCCCMintedByVIP += _amountToMint;
            totalETHDonatedByVIP += totalPrice;
        }

        emit MintCCC(msg.sender, _amountToMint);
    }

    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback from requestRandomness()
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(shuffleNumber == 0, "shuffleNumber is already set");
        shuffleNumber = randomness;
    }

    // Fisher-Yates shuffle to obtained shuffled array of 0 to maxCCC. token id #n will be picture shuffledArray[n]
    function shuffle() external view returns (uint256[] memory shuffledArray) {
        require(shuffleNumber > 0, "shuffleNumber is not set");
        // initialize array
        shuffledArray = new uint256[](maxCCC);
        for (uint256 i = 0; i < maxCCC; i++) {
            shuffledArray[i] = i;
        }
        uint256 entropy = shuffleNumber;

        for (uint256 i = maxCCC-1; i > 0; i--) {
            // select random number from 0 to i inclusive
            entropy = uint256(keccak256(abi.encode(entropy)));
            uint256 j = (entropy) % (i+1);

            // swap item i and j
            uint256 temp = shuffledArray[i];
            shuffledArray[i] = shuffledArray[j];
            shuffledArray[j] = temp;
        }
    }

    // withdraw eth for sold CCC
    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        require(_to != address(0), "receiver cant be empty address");

        // Send eth to designated receiver
        emit Withdraw(_to);

        _to.transfer(amount);
    }
}