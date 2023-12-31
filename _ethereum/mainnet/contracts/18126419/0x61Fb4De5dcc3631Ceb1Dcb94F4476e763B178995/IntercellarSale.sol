// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";
import "./MerkleProof.sol";
import "./Bottle.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract IntercellarSale is Ownable, PaymentSplitter {
    using SafeERC20 for ERC20;
    using ECDSA for bytes32;
    enum Phase {
        Pause,
        PreMint,
        PublicSale
    }

    bytes32 public merkleRoot;
    uint256 public constant DECIMAL_FACTOR = 1e6;
    uint256 public priceInEuro;
    uint256 public tolerance;
    bool public isCollectionHolders;
    address public collection;
    address public priceOracleEuro;
    address public signer;

    mapping(address => address) public priceOracle;
    Bottle public bottle;

    Phase public currentPhase;

    event NewBottleContract(address indexed bottle);

    constructor(
        address _bottleAddress,
        address _collection,
        uint256 _priceInEuro,
        uint256 _tolerance,
        address _signer,
        address[] memory _team,
        uint256[] memory _teamShares
    )  PaymentSplitter(_team, _teamShares) {
        bottle = Bottle(_bottleAddress);
        collection = _collection;
        currentPhase = Phase(1);
        priceInEuro = _priceInEuro;
        tolerance = _tolerance;
        signer = _signer;
    }

    function isValidSignature(
        address account,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 signedMessageHash = keccak256(abi.encodePacked(account, address(this), address(bottle)))
            .toEthSignedMessageHash();

        return signedMessageHash.recover(signature) == signer;
    }

    function preMint(
        address to,
        address token,
        uint8 amount,
        bytes32[] calldata proof,
        uint256 orderId,
        bytes calldata signature
    ) public payable {
        require(
            currentPhase == Phase(Phase.PreMint),
            "Pre mint phase not enabled"
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
        _pay(token, amount);
        bottle.batchMint(to, amount, orderId);
    }

    function publicMint(
        address to,
        address token,
        uint8 amount,
        uint256 orderId
    ) public payable {
        require(
            currentPhase == Phase(Phase.PublicSale),
            "Public mint phase not enabled"
        );
        _pay(token, amount);
        bottle.batchMint(to, amount, orderId);
    }

    function _pay(
        address token,
        uint256 amount
    ) internal {
        uint amountToPay = getPrice(token, amount);
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

    function getUsdByEuro() private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceOracleEuro)
            .latestRoundData();
        require(price > 0, "negative price");
        return uint256(price);
    }

    function getUsdByToken(address token) private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceOracle[token])
            .latestRoundData();
        require(price > 0, "negative price");
        return uint256(price);
    }

    function getPrice(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 priceInDollar = (priceInEuro * getUsdByEuro() * 10 ** 18) /
            10 ** AggregatorV3Interface(priceOracleEuro).decimals();
        uint256 price = (priceInDollar *
            10 ** (AggregatorV3Interface(priceOracle[token]).decimals())) /
            getUsdByToken(token);
        return ((price * amount) / DECIMAL_FACTOR);
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

    function setPrice(uint256 price_) public onlyOwner {
        priceInEuro = price_;
    }

    function setPhase(Phase _phase) public onlyOwner {
        currentPhase = Phase(_phase);
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
}
