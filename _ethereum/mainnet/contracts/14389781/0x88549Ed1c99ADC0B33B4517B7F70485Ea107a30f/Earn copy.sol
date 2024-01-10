//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";

contract Earn is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public ALTA;
    IERC20 public USDC;
    address loanAddress;
    address feeAddress;

    // Interest Bonus based off time late
    uint256 public baseBonusMultiplier;
    uint256 public altaBonusMultiplier;

    uint256 public transferFee;
    uint256 reserveDays;

    // USDC Amounts Needed for ALTA Value Tiers
    uint256 public highTier; // dollars + 6 decimals
    uint256 public medTier; // dollars + 6 decimals
    uint256 public lowTier; // dollars + 6 decimals

    event ContractOpened(address indexed owner, uint256 earnContractId);
    event ContractClosed(address indexed owner, uint256 earnContractId);
    event EarnContractOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 earnContractId
    );
    event BidMade(address indexed bidder, uint256 bidId);
    event ContractForSale(uint256 earnContractId);
    event ContractOffMarket(uint256 earnContractId);

    constructor(
        IERC20 _USDC,
        IERC20 _ALTA,
        address _loanAddress,
        address _feeAddress,
        EarnContract[] memory migratedContracts
    ) {
        USDC = _USDC;
        ALTA = _ALTA;
        baseBonusMultiplier = 150; //150 = 1.5x
        altaBonusMultiplier = 200; // 200 = 2x
        reserveDays = 7;
        loanAddress = _loanAddress;
        feeAddress = _feeAddress;
        for (uint256 i = 0; i < migratedContracts.length; i++) {
            _migrateContract(migratedContracts[i]);
        }
    }

    enum ContractStatus {
        OPEN,
        CLOSED,
        FORSALE
    }

    struct EarnTerm {
        // Time Locked (in Days);
        uint256 time;
        // USDC APR (simple interest) (1000 = 10%)
        uint16 usdcRate;
        // ALTA High Amount
        uint64 altaHighAmount;
        // ALTA Med Amount
        uint64 altaMedAmount;
        // ALTA Low Amount
        uint64 altaLowAmount;
        // Tokens other than ALTA accepted?
        bool otherTokens;
        // Tokens need to be whitelisted?
        bool whitelist;
        // Array of whitelisted tokens
        address[] tokensAccepted;
        // Max usdc accepted
        uint256 usdcMax;
        // Amount already accepted
        uint256 usdcAccepted;
        // True if open, False if closed
        bool open;
    }

    struct EarnContract {
        // Contract Owner Address
        address owner;
        // Unix Epoch time started
        uint256 startTime;
        // length of contract in seconds
        uint256 contractLength;
        // Address of token lent
        address tokenAddress;
        // Amount of token lent
        uint256 tokenAmount;
        // Amount sent to contract in USDC (swap value);
        uint256 usdcPrincipal;
        // USDC interest rate
        uint256 usdcRate;
        // USDC Interest Paid
        uint256 usdcInterestPaid;
        // ALTA interet rate
        uint256 altaAmount;
        // Rate usdc interest will be paid for days overdue
        uint256 usdcBonusRate;
        // Fixed ALTA bonus for overdue payment
        uint256 altaBonusAmount;
        // Open, Closed, or ForSale
        ContractStatus status;
    }

    struct Bid {
        // Bid Owner Address
        address bidder;
        // Address of Contract Owner
        address to;
        // Earn Contract Id
        uint256 earnContractId;
        // Amount
        uint256 amount;
        // Accepted - false if pending
        bool accepted;
    }

    // Comes with a public getter function
    EarnTerm[] public earnTerms;
    EarnContract[] public earnContracts;
    Bid[] public bids;

    // Maps the earn contract id to the owner
    mapping(uint256 => address) public earnContractToOwner;

    // Maps the number of earn contracts for a given user
    mapping(address => uint256) public ownerEarnContractCount;

    // Maps the number of bids per earn contract
    mapping(uint256 => uint256) public earnContractBidCount;

    /**
     * @param _time Length of the contract in days
     * @param _usdcRate Interest rate for USDC (1000 = 10%)
     * @param _altaHighAmount ALTA bonus for the high tier
     * @param _altaMedAmount ALTA bonus for the medium tier
     * @param _altaLowAmount ALTA bonus for the low tier
     * @dev Add an earn term with 8 parameters
     */
    function addTerm(
        uint256 _time,
        uint16 _usdcRate,
        uint64 _altaHighAmount,
        uint64 _altaMedAmount,
        uint64 _altaLowAmount,
        bool _otherTokens,
        bool _whitelist,
        address[] memory _tokensAccepted,
        uint256 _usdcMax
    ) public onlyOwner {
        earnTerms.push(
            EarnTerm(
                _time,
                _usdcRate,
                _altaHighAmount,
                _altaMedAmount,
                _altaLowAmount,
                _otherTokens,
                _whitelist,
                _tokensAccepted,
                _usdcMax,
                0,
                true
            )
        );
    }

    /**
     * Close an earn term
     * @param _earnTermsId index of the earn term in earnTerms
     */
    function closeTerm(uint256 _earnTermsId) public onlyOwner {
        _closeTerm(_earnTermsId);
    }

    function _closeTerm(uint256 _earnTermsId) internal {
        require(_earnTermsId < earnTerms.length);
        earnTerms[_earnTermsId].open = false;
    }

    /**
     * Close an earn term
     * @param _earnTermsId index of the earn term in earnTerms
     */
    function openTerm(uint256 _earnTermsId) public onlyOwner {
        require(_earnTermsId < earnTerms.length);
        earnTerms[_earnTermsId].open = true;
    }

    /**
     * @dev Update an earn term passing the individual parameters
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _time Length of the contract in days
     * @param _usdcRate Interest rate for USDC (1000 = 10%)
     * @param _altaHighAmount ALTA bonus for the high tier
     * @param _altaMedAmount ALTA bonus for the medium tier
     * @param _altaLowAmount ALTA bonus for the low tier
     */
    function updateTerm(
        uint256 _earnTermsId,
        uint256 _time,
        uint16 _usdcRate,
        uint64 _altaHighAmount,
        uint64 _altaMedAmount,
        uint64 _altaLowAmount,
        bool _otherTokens,
        bool _whitelist,
        address[] memory _tokensAccepted,
        uint256 _usdcMax,
        uint256 _usdcAccepted,
        bool _open
    ) public onlyOwner {
        earnTerms[_earnTermsId] = EarnTerm(
            _time,
            _usdcRate,
            _altaHighAmount,
            _altaMedAmount,
            _altaLowAmount,
            _otherTokens,
            _whitelist,
            _tokensAccepted,
            _usdcMax,
            _usdcAccepted,
            _open
        );
    }

    /**
     * @notice Use the public getter function for earnTerms for a single earnTerm
     * @return An array of type EarnTerm
     */
    function getAllEarnTerms() public view returns (EarnTerm[] memory) {
        return earnTerms;
    }

    /**
     * @notice Use the public getter function for earnTerms for a single earnTerm
     * @return An array of type EarnTerm with open == true
     */
    function getAllOpenEarnTerms() public view returns (EarnTerm[] memory) {
        EarnTerm[] memory result = new EarnTerm[](earnTerms.length);
        uint256 counter = 0;

        for (uint256 i = 0; i < earnTerms.length; i++) {
            if (earnTerms[i].open == true) {
                result[counter] = earnTerms[i];
                counter++;
            }
        }
        return result;
    }

    /**
     * @notice Use the public getter function for bids for a sinble bid
     * @return An array of type Bid
     */
    function getAllBids() public view returns (Bid[] memory) {
        return bids;
    }

    function getContractTier(uint256 _amount, EarnTerm memory earnTerm)
        internal
        view
        returns (uint256 altaAmount)
    {
        if (_amount >= highTier) {
            altaAmount = earnTerm.altaHighAmount;
        } else if (_amount >= medTier) {
            altaAmount = earnTerm.altaMedAmount;
        } else if (_amount >= lowTier) {
            altaAmount = earnTerm.altaLowAmount;
        } else {
            altaAmount = 0;
        }
        return altaAmount;
    }

    /**
     * Sends erc20 token to AltaFin Treasury Address and creates a contract with EarnContract[_id] terms for user.
     * User needs to approve USDC to be spent by this contract before calling this function
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _amount Amount of USDC principal
     */
    function openContractUsdc(uint256 _earnTermsId, uint256 _amount)
        public
        whenNotPaused
    {
        EarnTerm memory earnTerm = earnTerms[_earnTermsId];
        require(earnTerm.open);
        require(earnTerm.otherTokens, "Earn term doesn't accept USDC");
        if (earnTerm.whitelist) {
            // Check to see if token is on whitelist for earn term
            require(checkTokenWhitelist(address(USDC), _earnTermsId));
        }

        require(_amount > 0, "USDC amount must be greater than zero");
        // Check to see if the User has sufficient funds.
        require(
            USDC.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient Tokens"
        );

        earnTerms[_earnTermsId].usdcAccepted =
            earnTerms[_earnTermsId].usdcAccepted +
            _amount;
        require(
            earnTerms[_earnTermsId].usdcAccepted <=
                (earnTerms[_earnTermsId].usdcMax +
                    (earnTerms[_earnTermsId].usdcMax / 10))
        );

        if (
            earnTerms[_earnTermsId].usdcAccepted >=
            earnTerms[_earnTermsId].usdcMax
        ) {
            _closeTerm(_earnTermsId);
        }

        uint256 altaAmount = getContractTier(_amount, earnTerm);

        uint256 earnDays = earnTerm.time * 1 days;

        uint256 interestReserve = calculateInterestReserves(
            _amount,
            earnTerm.usdcRate
        );

        uint256 amount = _amount - interestReserve;

        USDC.safeTransferFrom(msg.sender, loanAddress, amount);
        USDC.safeTransferFrom(msg.sender, address(this), interestReserve);

        _createContract(
            earnTerm,
            earnDays,
            _amount,
            altaAmount,
            _amount,
            address(USDC)
        );
    }

    /**
     * Sends erc20 token to AltaFin Treasury Address and creates a contract with EarnContract[_id] terms for user.
     * @param _earnTermsId index of the earn term in earnTerms
     * @param _tokenAddress Contract address of input token
     * @param _amount Amount of token to be swapped for USDC principal
     */
    function openContractTokenSwapToUSDC(
        uint256 _earnTermsId,
        address _tokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes calldata _swapCallData
    ) public whenNotPaused {
        require(_amount > 0, "Token amount must be greater than zero");
        // User needs to first approve the token to be spent
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(address(msg.sender)) >= _amount,
            "Insufficient Tokens"
        );

        EarnTerm memory earnTerm = earnTerms[_earnTermsId];

        require(earnTerm.open, "Earn Term must be open");

        // Check if input token is ALTA
        if (_tokenAddress != address(ALTA)) {
            // Earn Term must accept other tokens
            require(earnTerm.otherTokens, "token not accepted");
            if (earnTerm.whitelist) {
                // Check to see if token is on whitelist for earn term
                require(checkTokenWhitelist(_tokenAddress, _earnTermsId));
            }
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Swap tokens for USDC
        uint256 amountUsdc = _swapToUSDCOnZeroX(
            _earnTermsId,
            _tokenAddress,
            _amount,
            payable(_swapTarget), // address payable swapTarget
            _swapCallData // bytes calldata swapCallData
        );

        earnTerms[_earnTermsId].usdcAccepted =
            earnTerms[_earnTermsId].usdcAccepted +
            amountUsdc;
        require(
            earnTerms[_earnTermsId].usdcAccepted <=
                (earnTerms[_earnTermsId].usdcMax +
                    (earnTerms[_earnTermsId].usdcMax / 10)),
            "usdc amount greater than max"
        );

        if (
            earnTerms[_earnTermsId].usdcAccepted >=
            earnTerms[_earnTermsId].usdcMax
        ) {
            _closeTerm(_earnTermsId);
        }

        uint256 altaAmount = getContractTier(amountUsdc, earnTerm);

        uint256 earnDays = earnTerm.time * 1 days;

        _createContract(
            earnTerm,
            earnDays,
            amountUsdc,
            altaAmount,
            _amount,
            _tokenAddress
        );
    }

    function _createContract(
        EarnTerm memory _earnTerm,
        uint256 _earnDays,
        uint256 _amountUsdc,
        uint256 _amountAlta,
        uint256 _assetAmount,
        address _assetAddress
    ) internal {
        EarnContract memory earnContract = EarnContract(
            msg.sender, // owner
            block.timestamp, // startTime
            _earnDays, //contractLength,
            _assetAddress, // tokenAddress
            _assetAmount, // tokenAmount
            _amountUsdc, // usdcPrincipal
            _earnTerm.usdcRate, // usdcRate
            0, // usdcInterestPaid
            _amountAlta, // altaAmount
            (_earnTerm.usdcRate * baseBonusMultiplier) / 100, // usdcBonusRate
            (_amountAlta * altaBonusMultiplier) / 100, // altaBonusAmount
            ContractStatus.OPEN
        );

        earnContracts.push(earnContract);
        uint256 id = earnContracts.length - 1;
        earnContractToOwner[id] = msg.sender; // assign the earn contract to the owner;
        ownerEarnContractCount[msg.sender] =
            ownerEarnContractCount[msg.sender] +
            1; // increment the number of earn contract owned for the user;
        emit ContractOpened(msg.sender, id);
    }

    function _migrateContract(EarnContract memory migrated) internal {
        EarnContract memory earnContract = EarnContract(
            migrated.owner, // owner
            migrated.startTime, // startTime
            migrated.contractLength, // contractLength,
            migrated.tokenAddress, // tokenAddress
            migrated.tokenAmount, // tokenAmount
            migrated.usdcPrincipal, // usdcPrincipal
            migrated.usdcRate, // usdcRate
            migrated.usdcInterestPaid, // usdcInterestPaid
            migrated.altaAmount, // altaAmount
            migrated.usdcBonusRate, // usdcBonusRate
            migrated.altaBonusAmount, // altaBonusAmount
            migrated.status
        );

        earnContracts.push(earnContract);
        uint256 id = earnContracts.length - 1;
        earnContractToOwner[id] = migrated.owner; // assign the earn contract to the owner;
        ownerEarnContractCount[migrated.owner] =
            ownerEarnContractCount[migrated.owner] +
            1; // increment the number of earn contract owned for the user;
        emit ContractOpened(migrated.owner, id);
    }

    /**
     * Sends the amount usdc and alta owed to the contract owner and deletes the EarnContract from the mapping.
     * @param _earnContractId index of earn contract in earnContracts
     */
    function closeContract(uint256 _earnContractId) external onlyOwner {
        require(
            earnContracts[_earnContractId].status != ContractStatus.CLOSED,
            "Contract is already closed"
        );
        (uint256 usdcAmount, uint256 altaAmount) = _calculatePaymentAmounts(
            _earnContractId
        );

        address owner = earnContracts[_earnContractId].owner;

        USDC.safeTransferFrom(msg.sender, address(owner), usdcAmount);
        ALTA.safeTransferFrom(msg.sender, address(owner), altaAmount);

        emit ContractClosed(owner, _earnContractId);

        _removeAllContractBids(_earnContractId);

        // Mark the contract as closed
        require(
            _earnContractId < earnContracts.length,
            "Contract Index not in the array"
        );

        earnContracts[_earnContractId].status = ContractStatus.CLOSED;
    }

    /**
     * Internal function to calculate the amount of USDC and ALTA needed to close an earnContract
     * @param _earnContractId index of earn contract in earnContracts
     */
    // TODO: Test this function thoroughly
    function _calculatePaymentAmounts(uint256 _earnContractId)
        internal
        view
        returns (uint256 usdcAmount, uint256)
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        (uint256 usdcInterestAmount, uint256 altaAmount) = calculateInterest(
            _earnContractId
        );
        usdcAmount = earnContract.usdcPrincipal + usdcInterestAmount;
        return (usdcAmount, altaAmount);
    }

    function redeemInterestUSDC(uint256 _earnContractId) public {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(earnContract.owner == msg.sender);
        (uint256 usdcInterestAmount, ) = calculateInterest(_earnContractId);
        earnContract.usdcInterestPaid =
            earnContract.usdcInterestPaid +
            usdcInterestAmount;
        USDC.safeTransfer(msg.sender, usdcInterestAmount);
    }

    function calculateInterest(uint256 _earnContractId)
        public
        view
        returns (uint256 usdcInterestAmount, uint256 altaAmount)
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        uint256 timeOpen = block.timestamp -
            earnContracts[_earnContractId].startTime;

        if (timeOpen <= earnContract.contractLength + 7 days) {
            // Calculate the total amount of usdc to be paid out (principal + interest)
            usdcInterestAmount =
                (earnContract.usdcPrincipal *
                    earnContract.usdcRate *
                    timeOpen) /
                365 days /
                10000;
            altaAmount = earnContract.altaAmount;
        } else {
            uint256 extraTime = timeOpen - earnContract.contractLength;
            uint256 usdcRegInterest = earnContract.usdcPrincipal +
                ((earnContract.usdcPrincipal *
                    earnContract.usdcRate *
                    earnContract.contractLength) /
                    365 days /
                    10000);

            uint256 usdcBonusInterest = (earnContract.usdcPrincipal *
                earnContract.usdcBonusRate *
                extraTime) /
                365 days /
                10000;
            usdcInterestAmount = usdcRegInterest + usdcBonusInterest;
            altaAmount = earnContract.altaBonusAmount;
        }

        usdcInterestAmount = usdcInterestAmount - earnContract.usdcInterestPaid;
        return (usdcInterestAmount, altaAmount);
    }

    function calculateInterestReserves(
        uint256 _usdcPrincipal,
        uint256 _usdcRate
    ) public view returns (uint256 usdcInterestAmount) {
        // Calculate the amount of usdc to be kept in address(this) upon earn contract creation
        usdcInterestAmount =
            (_usdcPrincipal * _usdcRate * reserveDays) /
            365 days /
            10000;
        return usdcInterestAmount;
    }

    /**
     * Sends all Ether in the contract to the specified wallet.
     * @param _addr Address of wallet to send ether
     */
    function withdraw(address payable _addr) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = _addr.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Sends all USDC in the contract to the specified wallet.
     * @param _addr Address of wallet to send USDC
     */
    function withdrawUSDC(address payable _addr) public onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.safeTransfer(_addr, amount);
    }

    /**
     * @param _to address of transfer recipient
     * @param _amount amount of ether to be transferred
     */
    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint256 _amount) public onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Gets the current value of all earn terms for a given user
     * @param _owner address of owner to query
     */
    function getCurrentUsdcValueByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        uint256[] memory result = getContractsByOwner(_owner);
        uint256 currValue = 0;

        for (uint256 i = 0; i < result.length; i++) {
            EarnContract memory earnContract = earnContracts[result[i]];
            if (earnContract.status != ContractStatus.CLOSED) {
                uint256 timeHeld = (block.timestamp - earnContract.startTime) /
                    365 days;
                currValue =
                    currValue +
                    earnContract.usdcPrincipal +
                    (earnContract.usdcPrincipal *
                        earnContract.usdcRate *
                        timeHeld);
            }
        }
        return currValue;
    }

    /**
     * Gets the value at time of redemption for all earns terms for a given user
     * @param _owner address of owner to query
     */
    function getRedemptionUsdcValueByOwner(address _owner)
        public
        view
        returns (uint256)
    {
        uint256[] memory result = getContractsByOwner(_owner);
        uint256 currValue = 0;

        for (uint256 i = 0; i < result.length; i++) {
            EarnContract memory earnContract = earnContracts[result[i]];
            if (earnContract.status != ContractStatus.CLOSED) {
                currValue =
                    currValue +
                    earnContract.usdcPrincipal +
                    (
                        ((earnContract.usdcPrincipal *
                            earnContract.usdcRate *
                            earnContract.contractLength) / 365 days)
                    );
            }
        }
        return currValue;
    }

    /**
     * Gets every earn contract for a given user
     * @param _owner Wallet Address for expected earn contract owner
     */
    function getContractsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerEarnContractCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < earnContracts.length; i++) {
            if (earnContractToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getAllEarnContracts() public view returns (EarnContract[] memory) {
        return earnContracts;
    }

    /**
     * Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     * @param _swapTarget 'To' field from the 0x API response
     * @param _swapCallData 'Data' field from the 0x API response
     */
    function _swapToUSDCOnZeroX(
        uint256 _earnTermId,
        address _token,
        uint256 _amount,
        // The `to` field from the API response.
        address payable _swapTarget,
        // The `data` field from the API response.
        bytes calldata _swapCallData
    ) internal returns (uint256) {
        uint256 currentUsdcBalance = USDC.balanceOf(address(this));

        require(IERC20(_token).approve(_swapTarget, _amount), "approve failed");

        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, ) = _swapTarget.call{value: msg.value}(_swapCallData);
        require(success, "SWAP_CALL_FAILED");

        uint256 usdcAmount = USDC.balanceOf(address(this)) - currentUsdcBalance;
        uint256 interestReserve = calculateInterestReserves(
            usdcAmount,
            earnTerms[_earnTermId].usdcRate
        );
        uint256 amount = usdcAmount - interestReserve;
        USDC.safeTransfer(loanAddress, amount);
        return usdcAmount;
    }

    /**
     * @param _token Token contract address
     * @param _earnTermsId Index of earn term in earnTerms
     */
    function checkTokenWhitelist(address _token, uint256 _earnTermsId)
        public
        view
        returns (bool)
    {
        EarnTerm memory earnTerm = earnTerms[_earnTermsId];
        for (uint256 i = 0; i < earnTerm.tokensAccepted.length; i++) {
            if (_token == earnTerm.tokensAccepted[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * Lists the associated earn contract for sale on the market
     * @param _earnContractId index of earn contract in earnContracts
     */
    function putSale(uint256 _earnContractId) external whenNotPaused {
        require(
            msg.sender == earnContractToOwner[_earnContractId],
            "Msg.sender is not the owner"
        );
        earnContracts[_earnContractId].status = ContractStatus.FORSALE;
        emit ContractForSale(_earnContractId);
    }

    /**
     * Submits a bid for an earn contract on sale in the market
     * User must sign an approval transaction for first. ALTA.approve(address(this), _amount);
     * @param _earnContractId index of earn contract in earnContracts
     * @param _amount Amount of ALTA offered for bid
     */
    function makeBid(uint256 _earnContractId, uint256 _amount)
        external
        whenNotPaused
    {
        EarnContract memory earnContract = earnContracts[_earnContractId];
        require(
            earnContract.status == ContractStatus.FORSALE,
            "Contract not for sale"
        );

        Bid memory bid = Bid(
            msg.sender, // bidder
            earnContract.owner, // to
            _earnContractId, // earnContractId
            _amount, // amount
            false // accepted
        );

        bids.push(bid);
        uint256 bidId = bids.length - 1;
        earnContractBidCount[_earnContractId] =
            earnContractBidCount[_earnContractId] +
            1; // increment the number of bids for the earn contract;

        // Send the bid amount to this contract
        ALTA.safeTransferFrom(msg.sender, address(this), _amount);
        emit BidMade(msg.sender, bidId);
    }

    /**
     * Called by the owner of the earn contract for sale
     * Transfers the bid amount to the owner of the earn contract and transfers ownership of the contract to the bidder
     * @param _bidId index of bid in Bids
     */
    function acceptBid(uint256 _bidId) external whenNotPaused {
        Bid memory bid = bids[_bidId];
        uint256 earnContractId = bid.earnContractId;

        uint256 fee = (bid.amount * transferFee) / 1000;
        if (fee > 0) {
            bid.amount = bid.amount - fee;
        }

        // Transfer bid ALTA to contract seller
        require(
            msg.sender == earnContractToOwner[earnContractId],
            "Msg.sender is not the owner of the earn contract"
        );
        if (fee > 0) {
            ALTA.safeTransfer(feeAddress, fee);
            bid.amount = bid.amount - fee;
        }
        ALTA.safeTransfer(bid.to, bid.amount);

        bids[_bidId].accepted = true;

        // Transfer ownership of earn contract to bidder
        emit EarnContractOwnershipTransferred(
            bid.to,
            bid.bidder,
            earnContractId
        );
        earnContracts[earnContractId].owner = bid.bidder;
        earnContractToOwner[earnContractId] = bid.bidder;
        ownerEarnContractCount[bid.bidder] =
            ownerEarnContractCount[bid.bidder] +
            1;

        // Remove all bids
        _removeContractFromMarket(earnContractId);
    }

    /**
     * Remove Contract From Market
     * @param _earnContractId index of earn contract in earnContracts
     */
    function removeContractFromMarket(uint256 _earnContractId) external {
        require(
            earnContractToOwner[_earnContractId] == msg.sender,
            "Msg.sender is not the owner of the earn contract"
        );
        _removeContractFromMarket(_earnContractId);
    }

    /**
     * Removes all contracts bids and sets the status flag back to open
     * @param _earnContractId index of earn contract in earnContracts
     */
    function _removeContractFromMarket(uint256 _earnContractId) internal {
        earnContracts[_earnContractId].status = ContractStatus.OPEN;
        _removeAllContractBids(_earnContractId);
        emit ContractOffMarket(_earnContractId);
    }

    /**
     * Getter functions for all bids of a specified earn contract
     * @param _earnContractId index of earn contract in earnContracts
     */
    function getBidsByContract(uint256 _earnContractId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](
            earnContractBidCount[_earnContractId]
        );
        uint256 counter = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].earnContractId == _earnContractId) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /**
     * Sends all bid funds for an earn contract back to the bidder and removes them arrays and mappings
     * @param _earnContractId index of earn contract in earnContracts
     */
    function _removeAllContractBids(uint256 _earnContractId) internal {
        uint256[] memory contractBids = getBidsByContract(_earnContractId);
        for (uint256 i = 0; i < contractBids.length; i++) {
            uint256 bidId = contractBids[0];
            Bid memory bid = bids[bidId];
            if (bid.accepted != true) {
                ALTA.safeTransfer(bid.bidder, bid.amount);
            }
            _removeBid(bidId);
        }
    }

    /**
     * Sends bid funds back to bidder and removes the bid from the array
     * @param _bidId index of bid in Bids
     */
    function removeBid(uint256 _bidId) external {
        Bid memory bid = bids[_bidId];
        require(msg.sender == bid.bidder, "Msg.sender is not the bidder");
        ALTA.safeTransfer(bid.bidder, bid.amount);

        _removeBid(_bidId);
    }

    // TODO: Test that the mappings and arrays are updated correctly
    /**
     * @param _bidId index of bid in Bids
     */
    function _removeBid(uint256 _bidId) internal {
        require(_bidId < bids.length, "Bid ID longer than array length");
        Bid memory bid = bids[_bidId];

        // Update the mappings
        uint256 earnContractId = bid.earnContractId;
        if (earnContractBidCount[earnContractId] > 0) {
            earnContractBidCount[earnContractId] =
                earnContractBidCount[earnContractId] -
                1;
        }

        // Update the array
        if (bids.length > 1) {
            bids[_bidId] = bids[bids.length - 1];
        }
        bids.pop();
    }

    /**
     * Set the lower bound USDC amount needed to receive the respective ALTA amounts
     * @param _highTier Minimum usdc amount needed to qualify for earn contract high tier
     * @param _medTier Minimum usdc amount needed to qualify for earn contract medium tier
     * @param _lowTier Minimum usdc amount needed to quallify for earn contract low tier
     */
    function setAltaContractTiers(
        uint256 _highTier,
        uint256 _medTier,
        uint256 _lowTier
    ) external onlyOwner {
        highTier = _highTier; // initially $150k
        medTier = _medTier; // initially $100k
        lowTier = _lowTier; // initially $50k
    }

    /**
     * Set the transfer fee rate for contracts sold on the market place
     * @param _transferFee Percent of accepted earn contract bid to be sent to AltaFin wallet
     */
    function setTransferFee(uint256 _transferFee) external onlyOwner {
        transferFee = _transferFee;
    }

    /**
     * Set ALTA ERC20 token address
     * @param _ALTA Address of ALTA Token contract
     */
    function setAltaAddress(address _ALTA) external onlyOwner {
        ALTA = IERC20(_ALTA);
    }

    /**
     * Set the reserveDays
     * @param _reserveDays Number of days interest to be stored in address(this) upon contract creation
     */
    function setReserveDays(uint256 _reserveDays) external onlyOwner {
        reserveDays = _reserveDays;
    }

    /**
     * Set the Bonus USDC multiplier ( e.g. 20 = 2x multiplier on the interest rate)
     * @param _baseBonusMultiplier Base Bonus multiplier for contract left open after contract length completion
     */
    function setBaseBonusMultiplier(uint256 _baseBonusMultiplier)
        external
        onlyOwner
    {
        baseBonusMultiplier = _baseBonusMultiplier;
    }

    /**
     * Set the Bonus ALTA multiplier ( e.g. 20 = 2x multiplier on the ALTA Amount)
     * @param _altaBonusMultiplier ALTA Bonus multiplier for contract left open after contract length completion
     */
    function setAltaBonusMultiplier(uint256 _altaBonusMultiplier)
        external
        onlyOwner
    {
        altaBonusMultiplier = _altaBonusMultiplier;
    }

    /**
     * Set the loanAddress
     * @param _loanAddress Wallet address to recieve loan funds
     */
    function setLoanAddress(address _loanAddress) external onlyOwner {
        require(_loanAddress != address(0));
        loanAddress = _loanAddress;
    }

    /**
     * Set the feeAddress
     * @param _feeAddress Wallet address to recieve fee funds
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0));
        feeAddress = _feeAddress;
    }

    /**
     * Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
