// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";
import "./MerkleProof.sol";
import "./Bottle.sol";
import "./EdmusCards.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract  EdmusSale is Ownable, PaymentSplitter {
    using SafeERC20 for ERC20;
    using ECDSA for bytes32;

    enum Phase {
        Pause,
        PreSale,
        Sale
    }

    enum CardCategory {
        Magnum,
        Jeroboam,
        Balthazar
    }

    bytes32 public merkleRoot;
    uint256 public bottlePerMagnum = 6;
    uint256 public bottlePerJeroboam = 12;
    uint256 public bottlePerBalthazar = 24;
    uint256 public constant DECIMAL_FACTOR = 1e6;
    uint256 public tolerance;
    bool public isCollectionHolders;
    address public collection;
    address public priceOracleEuro;
    address public signer;

    mapping(address => address) public priceOracle;
    mapping(CardCategory => uint256) public pricesInEuro;

    Bottle public bottle;
    EdmusCards public edmusCards;

    Phase public phase;

    event NewBottleContract(address indexed bottle);
    event NewCardsContract(address indexed edmusCards);
    event NewBottlePerCards(
        uint256 bottlePerMagnum,
        uint256 bottlePerJeroboam,
        uint256 bottlePerBalthazar
    );

    constructor(
        address _bottleAddress,
        address _edmusCardsAddress,
        address _collection,
        uint256 _tolerance,
        address _signer,
        uint256 [] memory _priceInEuro,
        address [] memory _team,
        uint256 [] memory _shares
    ) PaymentSplitter(_team, _shares) {
        bottle = Bottle(_bottleAddress);
        edmusCards = EdmusCards(_edmusCardsAddress);
        collection = _collection;
        phase = Phase.Pause;
        tolerance = _tolerance;
        signer = _signer;
        for (uint256 i = 0; i < _priceInEuro.length; i++) {
            pricesInEuro[CardCategory(i)] = _priceInEuro[i];
        }
    }

    function isValidSignature(
        address account,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 signedMessageHash = keccak256(abi.encodePacked(account, address(this), address(edmusCards)))
            .toEthSignedMessageHash();

        return signedMessageHash.recover(signature) == signer;
    }

    function preMint(
        address to,
        address token,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        bytes32[] calldata proof,
        uint256 orderId,
        bytes calldata signature
    ) public payable {
        require(
            phase == Phase.PreSale,
            "Not in PreSale phase"
        );

        if (isCollectionHolders) {
            require(
                ERC721(collection).balanceOf(to) > 0
                || isWhitelistedAddress(to, proof)
                || isValidSignature(to, signature),
                "Wallet is not whitelisted"
            );
        } else {
            require(
                isWhitelistedAddress(to, proof)
                || isValidSignature(to, signature),
                "Wallet is not whitelisted"
            );
        }

        _pay(
            token,
            amountMagnum,
            amountJeroboam,
            amountBalthazar
        );

        _mintCardsAndBottle(
            to,
            amountMagnum,
            amountJeroboam,
            amountBalthazar,
            orderId
        );

    }

    function publicMint(
        address to,
        address token,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 orderId
    ) public payable {
        require(
            phase == Phase.Sale,
            "Not in Sale phase"
        );

        _pay(
            token,
            amountMagnum,
            amountJeroboam,
            amountBalthazar
        );

        _mintCardsAndBottle(
            to,
            amountMagnum,
            amountJeroboam,
            amountBalthazar,
            orderId
        );
    }

    function _mintCardsAndBottle(
        address to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 orderId
    ) internal {
        uint256 bottlesAmount = amountMagnum * bottlePerMagnum + amountJeroboam * bottlePerJeroboam + amountBalthazar * bottlePerBalthazar;

        edmusCards.batchMint(
            to,
            amountMagnum,
            amountJeroboam,
            amountBalthazar,
            orderId
        );

        bottle.batchMint(
            to,
            bottlesAmount,
            orderId
        );
    }

    function _pay(
        address token,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar
    ) internal {
        uint256 amountToPay = 0;
        if (amountMagnum > 0) {
            amountToPay += getPrice(token, CardCategory.Magnum) * amountMagnum;
        }
        if (amountJeroboam > 0) {
            amountToPay += getPrice(token, CardCategory.Jeroboam) * amountJeroboam;
        }
        if (amountBalthazar > 0) {
            amountToPay += getPrice(token, CardCategory.Balthazar) * amountBalthazar;
        }

        if (token == address(0)) {
            _checkPayment(amountToPay, msg.value);
        } else {
            uint8 decimals = uint8(18) - ERC20(token).decimals();
            ERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                amountToPay / 10 ** decimals
            );
        }
    }

    function getPrice(
        address token,
        CardCategory cardCategory
    ) public view returns (uint256) {
        uint256 priceInDollar = (pricesInEuro[cardCategory] * getUsdByEuro() * 10**18) /
            10 ** AggregatorV3Interface(priceOracleEuro).decimals();
        uint256 price = (priceInDollar *
            10 ** AggregatorV3Interface(priceOracle[token]).decimals()) /
            getUsdByToken(token);
        return price / DECIMAL_FACTOR;
    }

    function getUsdByEuro() private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceOracleEuro).latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    function getUsdByToken(address token) private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceOracle[token]).latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    function _checkPayment(
        uint256 expectedAmount,
        uint256 sentAmount
    ) public view {
        //Checks for the difference between the price to be paid for all the NFTs being minted and the amount of ether sent in the transaction
        uint256 minPrice = ((expectedAmount * (1000 - tolerance)) / 1000);
        uint256 maxPrice = ((expectedAmount * (1000 + tolerance)) / 1000);
        require(sentAmount >= minPrice, "Not enough ETH");
        require(sentAmount <= maxPrice, "Too much ETH");
    }

    function isWhitelistedAddress(
        address _address,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        bytes32 addressHash = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_proof, merkleRoot, addressHash);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setOraclePrice(address token, address oracle) external onlyOwner {
        priceOracle[token] = oracle;
    }

    function setOraclePriceEuro(address oracle) external onlyOwner {
        priceOracleEuro = oracle;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setTolerance(uint256 _tolerance) public onlyOwner {
        require(_tolerance <= 1000, "max value");
        tolerance = _tolerance;
    }

    function setPrices(uint256 priceMagnum, uint256 priceJeroboam, uint256 priceBalthazar) public onlyOwner {
        pricesInEuro[CardCategory.Magnum] = priceMagnum;
        pricesInEuro[CardCategory.Jeroboam] = priceJeroboam;
        pricesInEuro[CardCategory.Balthazar] = priceBalthazar;
    }

    function setPhase(Phase _phase) public onlyOwner {
        phase = Phase(_phase);
    }

    function setCollection(address _collection) public onlyOwner {
        collection = _collection;
    }

    function setIsCollectionHolders(
        bool _isCollectionHolders
    ) public onlyOwner {
        isCollectionHolders = _isCollectionHolders;
    }

    function setBottle(address _bottle) public onlyOwner {
        bottle = Bottle(_bottle);
        emit NewBottleContract(_bottle);
    }

    function setCards(address _cards) public onlyOwner {
        edmusCards = EdmusCards(_cards);
        emit NewCardsContract(_cards);
    }

    function setBottlePerCards(
        uint _bottlePerMagnum,
        uint _bottlePerJeroboam,
        uint _bottlePerBalthazar
    ) public onlyOwner {
        bottlePerMagnum = _bottlePerMagnum;
        bottlePerJeroboam = _bottlePerJeroboam;
        bottlePerBalthazar = _bottlePerBalthazar;
        emit NewBottlePerCards(_bottlePerMagnum, _bottlePerJeroboam, _bottlePerBalthazar);
    }

}
