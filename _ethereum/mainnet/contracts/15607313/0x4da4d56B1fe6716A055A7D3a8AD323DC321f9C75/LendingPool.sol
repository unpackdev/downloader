//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721A.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Math.sol";

contract LendingPool is Ownable, ERC721A {
    using Address for address payable;

    struct Loan {
        uint nft;
        uint startInterestSum;
        uint40 startTime; // safe until year 231,800
        uint216 borrowed; // would need to borrow 1e+47 ETH -> that much ETH doesnt even exist
    }

    IERC721 public immutable nftContract;
    uint256 public immutable maxLoanLength;
    uint256 public immutable maxInterestPerEthPerSecond; // eg: 80% p.a. = 25367833587 ~ 0.8e18 / 1 years;
    address public immutable factory;
    uint256 public maxPrice;
    address public oracle;
    uint public sumInterestPerEth = 0;
    uint public lastUpdate;
    uint public totalBorrowed = 0;
    mapping(uint=>Loan) public loans;
    string private baseURI = "https://nft.llamalend.com/nft/";
    uint maxDailyBorrows; // IMPORTANT: an attacker can borrow up to 150% of this limit if they prepare beforehand
    uint currentDailyBorrows;
    uint lastUpdateDailyBorrows;
    address[] public liquidators;

    event Borrowed(uint currentDailyBorrows, uint newBorrowedAmount);
    event ReducedDailyBorrows(uint currentDailyBorrows, uint amountReduced);

    constructor(address _oracle, uint _maxPrice, address _nftContract,
        uint _maxDailyBorrows, string memory _name, string memory _symbol,
        uint _maxLoanLength, uint _maxInterestPerEthPerSecond, address _owner) ERC721A(_name, _symbol)
    {
        oracle = _oracle;
        maxPrice = _maxPrice;
        nftContract = IERC721(_nftContract);
        lastUpdate = block.timestamp;
        maxDailyBorrows = _maxDailyBorrows;
        lastUpdateDailyBorrows = block.timestamp;
        maxLoanLength = _maxLoanLength;
        maxInterestPerEthPerSecond = _maxInterestPerEthPerSecond;
        transferOwnership(_owner);
        factory = msg.sender;
    }

    modifier updateInterest() {
        uint elapsed = block.timestamp - lastUpdate;
        // this can't overflow
        // if we assume elapsed = 10 years = 10*365*24*3600 = 315360000
        // and totalBorrowed = 1M eth = 1e6*1e18 = 1e24
        // then that's only 142.52 bits, way lower than the 256 bits required for it to overflow.
        // There's one attack where you could blow up totalBorrowed by cycling borrows,
        // but since this requires a tubby each time it can only be done 20k times, which only increase bits by 14.28 -> still safu
        // `address(this).balance - msg.value` can never underflow because msg.value is always < address(this).balance
        sumInterestPerEth += (elapsed * totalBorrowed * maxInterestPerEthPerSecond) / (address(this).balance - msg.value + totalBorrowed + 1); // +1 prevents divisions by 0
        lastUpdate = block.timestamp;
        _;
    }

    // copy of updateInterest() with msg.value = 0
    modifier updateInterestNonpayable() {
        uint elapsed = block.timestamp - lastUpdate;
        sumInterestPerEth += (elapsed * totalBorrowed * maxInterestPerEthPerSecond) / (address(this).balance + totalBorrowed + 1);
        lastUpdate = block.timestamp;
        _;
    }

    function addDailyBorrows(uint toAdd) internal {
        uint elapsed = block.timestamp - lastUpdateDailyBorrows;
        currentDailyBorrows = (currentDailyBorrows - Math.min((maxDailyBorrows*elapsed)/(1 days), currentDailyBorrows)) + toAdd;
        require(currentDailyBorrows < maxDailyBorrows, "max daily borrow");
        lastUpdateDailyBorrows = block.timestamp;
        emit Borrowed(currentDailyBorrows, toAdd);
    }

    function _borrow(
        uint nftId,
        uint216 price,
        uint index) internal {
        require(nftContract.ownerOf(nftId) == msg.sender, "not owner");
        loans[_nextTokenId() + index] = Loan(nftId, sumInterestPerEth, uint40(block.timestamp), price);
        nftContract.transferFrom(msg.sender, address(this), nftId);
    }

    function borrow(
        uint[] calldata nftId,
        uint216 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) external updateInterestNonpayable {
        checkOracle(price, deadline, v, r, s);
        uint length = nftId.length;
        totalBorrowed += price * length;
        for(uint i=0; i<length; i++){
            _borrow(nftId[i], price, i);
        }
        uint borrowedNow = price * length;
        addDailyBorrows(borrowedNow);
        _mint(msg.sender, length);
        payable(msg.sender).sendValue(borrowedNow);
    }

    function _repay(uint loanId) internal returns (uint) {
        require(ownerOf(loanId) == msg.sender, "not owner");
        Loan storage loan = loans[loanId];
        uint sinceLoanStart = block.timestamp - loan.startTime;
        uint interest = ((sumInterestPerEth - loan.startInterestSum) * loan.borrowed) / 1e18;
        if(sinceLoanStart > maxLoanLength){
            uint loanEnd = loan.startTime + maxLoanLength;
            interest += ((block.timestamp - loanEnd)*loan.borrowed)/(1 days);
        }
        _burn(loanId);
        totalBorrowed -= loan.borrowed;
        nftContract.transferFrom(address(this), msg.sender, loan.nft);

        if(sinceLoanStart < (1 days)){
            uint until24h;
            unchecked {
                until24h = (1 days) - sinceLoanStart;
            }
            uint toReduce = Math.min((loan.borrowed*until24h)/(1 days), currentDailyBorrows);
            currentDailyBorrows = currentDailyBorrows - toReduce;
            emit ReducedDailyBorrows(currentDailyBorrows, toReduce);
        }

        return interest + loan.borrowed;
    }

    function repay(uint[] calldata loanIds) external payable updateInterest {
        uint length = loanIds.length;
        uint totalToRepay = 0;
        for(uint i=0; i<length; i++){
            totalToRepay += _repay(loanIds[i]);
        }
        payable(msg.sender).sendValue(msg.value - totalToRepay); // overflow checks implictly check that amount is enough
    }

    function claw(uint loanId, uint liquidatorIndex) external updateInterestNonpayable {
        require(liquidators[liquidatorIndex] == msg.sender);
        Loan storage loan = loans[loanId];
        require(_exists(loanId), "loan closed");
        require(block.timestamp > (loan.startTime + maxLoanLength), "not expired");
        _burn(loanId);
        totalBorrowed -= loan.borrowed;
        nftContract.transferFrom(address(this), msg.sender, loan.nft);
    }

    function setOracle(address newValue) external onlyOwner {
        oracle = newValue;
    }

    function setMaxDailyBorrows(uint _maxDailyBorrows) external onlyOwner {
        maxDailyBorrows = _maxDailyBorrows;
    }

    function deposit() external payable onlyOwner updateInterest {}

    function withdraw(uint amount) external onlyOwner updateInterestNonpayable {
        payable(msg.sender).sendValue(amount);
    }

    function checkOracle(
        uint216 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view {
        require(block.timestamp < deadline, "deadline over");
        require(
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n111",
                        price,
                        deadline,
                        block.chainid,
                        address(nftContract)
                    )
                ),
                v,
                r,
                s
            ) == oracle,
            "not oracle"
        );
        require(price < maxPrice, "max price");
    }

    function currentSumInterestPerEth() view public returns (uint) {
        uint elapsed = block.timestamp - lastUpdate;
        return sumInterestPerEth + (elapsed * totalBorrowed * maxInterestPerEthPerSecond) / (address(this).balance + totalBorrowed + 1);
    }

    function infoToRepayLoan(uint loanId) view external returns (uint deadline, uint totalRepay, uint principal, uint interest, uint lateFees){
        Loan storage loan = loans[loanId];
        deadline = loan.startTime + maxLoanLength;
        interest = ((currentSumInterestPerEth() - loan.startInterestSum) * loan.borrowed) / 1e18;
        if(block.timestamp > deadline){
            lateFees = ((block.timestamp - deadline)*loan.borrowed)/(1 days);
        } else {
            lateFees = 0;
        }
        principal = loan.borrowed;
        totalRepay = principal + interest + lateFees;
    }

    function currentAnnualInterest(uint priceOfNextItem) external view returns (uint interest) {
        uint borrowed = priceOfNextItem + totalBorrowed;
        return (365 days * borrowed * maxInterestPerEthPerSecond) / (address(this).balance + totalBorrowed + 1);
    }

    function getDailyBorrows() external view returns (uint dailyBorrows, uint maxDailyBorrowsLimit) {
        uint elapsed = block.timestamp - lastUpdateDailyBorrows;
        dailyBorrows = currentDailyBorrows - Math.min((maxDailyBorrows*elapsed)/(1 days), currentDailyBorrows);
        maxDailyBorrowsLimit = maxDailyBorrows;
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(block.chainid), "/", Strings.toHexString(uint160(address(this)), 20), "/", Strings.toHexString(uint160(address(nftContract)), 20), "/"));
    }

    function setMaxPrice(uint newMaxPrice) external onlyOwner {
        maxPrice = newMaxPrice;
    }

    function addLiquidator(address liq) external onlyOwner {
        liquidators.push(liq);
    }

    function removeLiquidator(uint index) external onlyOwner {
        liquidators[index] = address(0);
    }

    function liquidatorsLength() external view returns (uint){
        return liquidators.length;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function emergencyShutdown() external {
        require(msg.sender == factory);
        maxPrice = 0; // prevents new borrows
    }

    fallback() external {
        // money can still be received through self-destruct, which makes it possible to change balance without calling updateInterest, but if
        // owner does that -> they are lowering the money they earn through interest
        // debtor does that -> they always lose money because all loans are < 2 weeks
        revert();
    }
}
