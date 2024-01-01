// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Initializable.sol";
import "./IERC20.sol";
import "./IAccess.sol";

contract HotWallet is Initializable {
    uint256 public BUY_LIMIT;
    address public azx;
    address public accessControl;

    mapping(bytes32 => SaleRequest) public saleRequests; // Mapping to track sale requests

    struct SaleRequest {
        bytes32 saleId;
        address seller;
        uint256 amount;
        bool isApproved;
        bool isProcessed;
    }

    event Buy(address indexed buyer, uint256 amount);
    event BuyWithSignature(
        address indexed buyer,
        address signer,
        address caller,
        uint256 amount
    );
    event TokenSold(
        string actionType,
        address signer,
        address manager,
        address to,
        uint256 amount,
        uint256 networkFee
    );
    event SaleRequestCreated(
        bytes32 saleId,
        address indexed seller,
        uint256 amount
    );
    event SaleRequestProcessed(address admin, bytes32 saleId, bool isApproved);
    event BuyLimitUpdated(uint256 newLimit);
    event TokensWithdrawn(address token, address to, uint256 amount);

    modifier onlyOwner() {
        require(
            IAccess(accessControl).isOwner(msg.sender),
            "HotWallet: Only the owner is allowed"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IAccess(accessControl).isSender(msg.sender),
            "HotWallet: Only managers are allowed"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _azx, address _access) external initializer {
        accessControl = _access;
        azx = _azx;
        BUY_LIMIT = 5000 * 10 ** 8;
    }

    /**
     * @notice Send AZX tokens from this contract to a user with an amount limit
     * @dev Only managers can call this function
     * @param _buyer The address of the user
     * @param _amount The amount of AZX
     */
    function buy(address _buyer, uint256 _amount) external onlyManager {
        require(
            _amount <= BUY_LIMIT,
            "HotWallet: Amount exceeds the buy limit"
        );
        require(_buyer != address(0), "HotWallet: Zero address is not allowed");
        IERC20(azx).transfer(_buyer, _amount);

        emit Buy(_buyer, _amount);
    }

    /**
     * @notice Update the limit for buying without a second manager's signature
     * @dev Only the owner can call this function
     * @param _limit The limit for buying without a second manager's signature
     */
    function updateBuyLimit(uint256 _limit) external onlyOwner {
        BUY_LIMIT = _limit;

        emit BuyLimitUpdated(_limit);
    }

    /**
     * @notice Withdraw any token from the contract
     * @dev Only the owner can call this function
     * @param _token The token address to withdraw
     * @param _to The destination address
     * @param _amount The amount to withdraw
     */
    function withdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "HotWallet: Zero address is not allowed");
        IERC20(_token).transfer(_to, _amount);

        emit TokensWithdrawn(_token, _to, _amount);
    }

    /**
     * @notice Send AZX tokens from this contract to a user without a limit and with a second manager's signature
     * @dev Only managers can call this function
     * @param signature The signature
     * @param token The unique token for each delegated function
     * @param buyer The fee that will be paid to the relayer for the gas fee spent
     * @param amount The amount to be allowed
     */
    function buyWithSignature(
        bytes memory signature,
        bytes32 token,
        address buyer,
        uint256 amount
    ) external onlyManager {
        bytes32 message = getBuyProof(token, buyer, amount);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isSigner(signer),
            "HotWallet: Signer is not a manager"
        );
        IERC20(azx).transfer(buyer, amount);

        emit BuyWithSignature(buyer, signer, msg.sender, amount);
    }

    /**
     * @notice Delegated sale of AZX (takes tokens and creates a request). Gas fee will be paid by the relayer
     * @param signature The signature
     * @param token The unique token for each delegated function
     * @param networkFee The fee that will be paid to the relayer for the gas fee spent
     * @param amount The array of amounts to be sold
     */
    function preAuthorizedSell(
        bytes memory signature,
        bytes32 token,
        address seller,
        uint256 amount,
        bytes32 saleId,
        uint256 networkFee
    ) public onlyManager returns (bool) {
        bytes32 message = getSaleProof(token, seller, amount, networkFee);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(seller == signer, "HotWallet: Signer is not the seller");
        IERC20(azx).transferFrom(seller, msg.sender, networkFee);
        IERC20(azx).transferFrom(seller, address(this), amount);
        require(
            saleRequests[saleId].seller == address(0),
            "HotWallet: Sale ID already exists"
        );
        saleRequests[saleId] = SaleRequest(
            saleId,
            signer,
            amount,
            false,
            false
        );
        emit SaleRequestCreated(saleId, seller, amount);

        return true;
    }

    /**
     * @notice Admins approve or reject a sale request
     * @dev The signer of the signature and the transaction sender must be different and both must be admins
     * @param saleId The ID of the sale request
     * @param isApproved Admins' decision about the request
     */
    function processSaleRequest(
        bytes memory signature,
        bytes32 token,
        bytes32 saleId,
        bool isApproved
    ) external onlyManager {
        bytes32 message = getSaleProcessProof(token, saleId, isApproved);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isSigner(signer),
            "HotWallet: Signer is not a manager"
        );
        require(
            saleRequests[saleId].isProcessed == false,
            "HotWallet: Request is already processed"
        );
        require(
            saleRequests[saleId].seller != address(0),
            "HotWallet: Request does not exist"
        );
        if (!isApproved) {
            require(
                IERC20(azx).transfer(
                    saleRequests[saleId].seller,
                    saleRequests[saleId].amount
                ),
                "HotWallet: Transfer error"
            );
        }
        saleRequests[saleId].isProcessed = true;
        saleRequests[saleId].isApproved = isApproved;
        emit SaleRequestProcessed(signer, saleId, isApproved);
    }

    /**
     * @dev Get the ID of the executing chain
     * @return uint256 value
     */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Get proof for an admin for buying with a signature
     */
    function getBuyProof(
        bytes32 token,
        address buyer,
        uint256 amount
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), token, buyer, amount)
        );
    }

    /**
     * @notice Get proof for a user for signing sale operations of its tokens
     */
    function getSaleProof(
        bytes32 token,
        address seller,
        uint256 amount,
        uint256 networkFee
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), token, seller, amount, networkFee)
        );
    }

    /**
     * @notice Get proof for an admin for processing a sale request
     */
    function getSaleProcessProof(
        bytes32 token,
        bytes32 saleId,
        bool isApproved
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), token, saleId, isApproved)
        );
    }
}
