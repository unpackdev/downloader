//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface IOracle {
    function lastAnswer() external view returns (int256);
}

contract MARS is Ownable, ReentrancyGuard {

    // Eclipse Token
    address public eclipse;

    // Listing Data
    struct ListedToken {
        uint256 listedIndex;
        uint256 amount;
        uint256 lastContribute;
        bool isNFT;
        bool isNSFW;
    }

    // token => listing data
    mapping (address => ListedToken) public listedTokens;

    // array of listed tokens
    address[] public listed;

    // Applicants
    struct Applicant {
        uint index;
        uint feeCharged;
        address user;
        address ref;
    }
    address[] public applicants;
    mapping ( address => Applicant ) public applicationInfo;

    // Referral Structure
    struct Ref {
        uint256 cut;
        uint256 totalEarned;
        address[] tokenReferrals;
    }

    // Referrer Structure
    mapping ( address => Ref ) public refInfo;

    // address => is authorized
    mapping ( address => bool ) public authorized;
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == this.getOwner(), 'Only Authorized');
        _;
    }

    // Decay Rate
    uint256 public decay_per_second = 165343916000;
    uint256 private constant DENOM = 10**18;

    // Listing Fees
    uint256 public listingFee;

    // Recipient
    address public eclipseRecipient;
    address public listingRecipient;

    // Default Referrer Fee
    uint256 public default_referral_fee = 10;

    // Chainlink Oracle Address
    address public oracle;

    // decimals of oracle
    uint8 public oracle_decimals;

    // Events
    event Applied(address indexed user, address ref, uint256 listingFee);
    event FundedEclipse(address token, address funder, uint256 amount);

    constructor(address eclipse_, uint listingFee_) {
        eclipse = eclipse_;
        listingFee = listingFee_;
    }

    function getLatestPrice() public view returns (uint256) {
        int256 answer = IOracle(oracle).lastAnswer();
        if (answer <= 0) {
            return 0;
        }
        return uint256(answer);
    }

    function setOracle(address oracle_) external onlyOwner {
        require(
            oracle_ != address(0),
            'Zero Addr'
        );
        oracle = oracle_;
    }

    function setOracleDecimals(uint8 newDecimals) external onlyOwner {
        oracle_decimals = newDecimals;
    }

    function setListingFee(uint newFee) external onlyOwner {
        listingFee = newFee;
    }

    function setDefaultReferralFee(uint newDefault) external onlyOwner {
        require(
            newDefault > 0 && newDefault < 50,
            'Fee Out Of Bounds'
        );
        default_referral_fee = newDefault;
    }

    function upgrade(address oldToken, address newToken) external onlyOwner {
        require(
            isListed(oldToken),
            'Token Not Listed'
        );
        listedTokens[newToken] = listedTokens[oldToken];
    }

    function awardPoints(address token, uint256 numPoints) external onlyOwner {
        require(
            isListed(token),
            'Token Not Listed'
        );

        // add new points to amount
        unchecked {
            listedTokens[token].amount += numPoints;
        }

        // reset last contribution timestamp
        listedTokens[token].lastContribute = block.timestamp;
    }

    function setEclipse(address eclipse_) external onlyOwner {
        require(
            eclipse_ != address(0),
            'Zero Addr'
        );
        eclipse = eclipse_;
    }

    function setAuthorized(address account, bool isAuth) external onlyOwner {
        authorized[account] = isAuth;
    }

    function delistToken(address token) external onlyOwner {
        require(isListed(token),
            'Not Listed'
        );
        listed[listedTokens[token].listedIndex] = listed[listed.length-1];
        listedTokens[listed[listed.length-1]].listedIndex = listedTokens[token].listedIndex;
        listed.pop();
        delete listedTokens[token];
    }

    function setDecayPerSecond(uint newDecay) external onlyOwner {
        decay_per_second = newDecay;
    }

    function setEclipseRecipient(address newRecipient) external onlyOwner {
        require(
            newRecipient != address(0),
            'Zero Addr'
        );
        eclipseRecipient = newRecipient;
    }

    function setListingRecipient(address newRecipient) external onlyOwner {
        require(
            newRecipient != address(0),
            'Zero Addr'
        );
        listingRecipient = newRecipient;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setReferralCut(address ref, uint cut) external onlyOwner {
        require(
            cut > 0,
            'Must Have Cut'
        );
        require(
            cut < 100,
            'Cut Cannot Be 100%'
        );
        require(
            ref != address(0),
            'Zero Addr'
        );
        refInfo[ref].cut = cut;
    }

    function removeReferrerCut(address ref) external onlyOwner {
        require(
            ref != address(0),
            'Zero Addr'
        );
        delete refInfo[ref].cut;
    }

    function listTokenWithoutApplication(address token, bool isNFT) external onlyOwner {
        require(
            token != address(0),
            'Zero Addr'
        );
        require(
            !isListed(token),
            'Already Listed'
        );
        require(
            !isApplicant(token),
            'Token Already Applied'
        );
        
        // listed data
        listedTokens[token].listedIndex = listed.length;
        listedTokens[token].isNFT = isNFT;
        listed.push(token);
    }

    function listToken(address token, bool isNFT, bool isNSFW) external onlyAuthorized nonReentrant {
        require(
            token != address(0),
            'Zero Addr'
        );
        require(
            !isListed(token),
            'Already Listed'
        );
        require(
            isApplicant(token),
            'Token Did Not Apply'
        );
        
        // listed data
        listedTokens[token].listedIndex = listed.length;
        listedTokens[token].isNFT = isNFT;
        listedTokens[token].isNSFW = isNSFW;
        listed.push(token);

        // application fee
        uint fee = applicationInfo[token].feeCharged;

        // referrer
        address ref = applicationInfo[token].ref;

        // remove applicant
        _removeApplicant(token);
        
        // forward fee
        if (fee > 0) {
            if (ref != address(0)) {

                // split fee
                uint refCut = getReferralFee(fee, ref);
                uint rest = fee - refCut;

                // send fee to listing recipient
                (bool s,) = payable(listingRecipient).call{value: rest}("");
                require(s, 'BNB TRANSFER FAIL');

                // send fee to referrer
                (s,) = payable(ref).call{value: refCut}("");
                require(s, 'BNB TRANSFER FAIL');

                // track how many fees were received by referrer
                unchecked {
                    refInfo[ref].totalEarned += refCut;
                }

                // add to referrers list
                refInfo[ref].tokenReferrals.push(token);

            } else {

                // no referrer, send entire fee to listing recipient
                (bool s,) = payable(listingRecipient).call{value: fee}("");
                require(s, 'BNB TRANSFER FAIL');

            }
        }
    }

    function rejectApplication(address token) external onlyAuthorized nonReentrant {
        require(
            token != address(0),
            'Zero Addr'
        );
        require(
            isApplicant(token),
            'Not Applicant'
        );

        // fetch data
        uint refund = applicationInfo[token].feeCharged;
        address user = applicationInfo[token].user;

        // remove applicant
        _removeApplicant(token);

        // refund user
        (bool s,) = payable(user).call{value: refund}("");
        require(s, 'BNB TRANSFER FAIL');
    }

    function setNSFW(address token, bool isNSFW) external onlyAuthorized {
        require(
            token != address(0),
            'Zero Addr'
        );
        require(
            isListed(token),
            'Token Not Listed'
        );
        listedTokens[token].isNSFW = isNSFW;
    }

    function getUSDValue(uint256 value) external view returns (uint256) {
        uint256 lastPrice = getLatestPrice();
        if (lastPrice == 0) {
            return 0;
        }
        return ( value * lastPrice ) / 10**oracle_decimals;
    }

    function getValueForListing() external view returns (uint256) {
        uint256 lastPrice = getLatestPrice();
        if (lastPrice == 0) {
            return 0;
        }
        uint256 num = listingFee / 10**oracle_decimals;
        uint256 denom = lastPrice * 10**(18 - oracle_decimals);
        return ( 10**18 * num ) / denom;
    }

    function Apply(address ref, address token) external payable {
        require(
            token != address(0),
            'Non Token'
        );
        require(
            !isApplicant(token),
            'Already Applied'
        );

        // fetch and validate latest price
        uint256 lastPrice = getLatestPrice();
        require(
            lastPrice > 0,
            'Invalid Oracle Response'
        );

        // convert price to USD
        uint256 usdValue = ( msg.value * lastPrice ) / 10**oracle_decimals;
        require(
            usdValue >= listingFee,
            'Invalid Fee'
        );

        // We allow no referrer
        if (ref != address(0)) {
            applicationInfo[token].ref = ref;
        }

        applicationInfo[token].index = applicants.length;
        applicationInfo[token].feeCharged = msg.value;
        applicationInfo[token].user = msg.sender;
        applicants.push(token);

        emit Applied(msg.sender, ref, msg.value);
    }

    function addToEclipse(address token, uint256 amount) external nonReentrant {
        require(
            IERC20(eclipse).allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        require(
            IERC20(eclipse).balanceOf(msg.sender) >= amount,
            'Insufficient Balance'
        );

        // transfer tokens from sender to eclipse recipient
        IERC20(eclipse).transferFrom(msg.sender, eclipseRecipient, amount);

        // decay balance if applicable
        if (timeSince(token) > 0) {
            listedTokens[token].amount = getPoints(token);
        }

        // add new donation to amount
        unchecked {
            listedTokens[token].amount += amount;
        }
        listedTokens[token].lastContribute = block.timestamp;

        emit FundedEclipse(token, msg.sender, amount);
    }

    function _removeApplicant(address applicant) internal {
        applicants[applicationInfo[applicant].index] = applicants[applicants.length-1];
        applicationInfo[applicants[applicants.length-1]].index = applicationInfo[applicant].index;
        applicants.pop();
        delete applicationInfo[applicant];
    }

    function getReferralFee(uint256 amount, address ref) public view returns (uint256 refFee) {
        uint256 refCut = refInfo[ref].cut == 0 ? default_referral_fee : refInfo[ref].cut;
        return ( amount * refCut ) / 100;
    }

    function getPoints(address token) public view returns (uint256) {
        if (listedTokens[token].amount == 0 || listedTokens[token].lastContribute == 0) {
            return 0;
        }

        uint prev = listedTokens[token].amount;
        uint timeSince_ = timeSince(token);

        uint decay = prev * timeSince_ * decay_per_second / DENOM;

        return decay >= prev ? 0 : prev - decay;
    }

    function timeSince(address token) public view returns (uint256) {
        if (listedTokens[token].lastContribute == 0) {
            return 0;
        }

        return block.timestamp > listedTokens[token].lastContribute ? block.timestamp - listedTokens[token].lastContribute : 0;
    }

    function getListedTokens() public view returns (address[] memory) {
        return listed;
    }

    function getListedTokensAndPoints() public view returns (address[] memory, uint256[] memory) {
        uint len = listed.length;
        uint256[] memory points = new uint256[](len);
        for (uint i = 0; i < len;) {
            points[i] = getPoints(listed[i]);
            unchecked { ++i; }
        }
        return (listed, points);
    }

    function getListedTokensAndPointsAndTypeFlag() public view returns (
        address[] memory,
        uint256[] memory,
        bool[] memory isNFTList,
        bool[] memory isNSFWList
    ) {

        uint len = listed.length;
        uint256[] memory points = new uint256[](len);
        isNFTList = new bool[](len);
        isNSFWList = new bool[](len);
        for (uint i = 0; i < len;) {
            points[i] = getPoints(listed[i]);
            isNFTList[i] = listedTokens[listed[i]].isNFT;
            isNSFWList[i] = listedTokens[listed[i]].isNSFW;
            unchecked { ++i; }
        }
        return (listed, points, isNFTList, isNSFWList);
    }

    function getPaginatedListedTokensAndPointsAndTypeFlag(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (
        address[] memory,
        uint256[] memory,
        bool[] memory isNFTList,
        bool[] memory isNSFWList
    ) {

        address[] memory listeds = new address[](endIndex - startIndex);
        uint256[] memory points = new uint256[](endIndex - startIndex);
        isNFTList = new bool[](endIndex - startIndex);
        isNSFWList = new bool[](endIndex - startIndex);
        uint count = 0;
        for (uint i = startIndex; i < endIndex;) {
            listeds[count] = listed[i];
            points[count] = getPoints(listed[i]);
            isNFTList[count] = listedTokens[listed[i]].isNFT;
            isNSFWList[count] = listedTokens[listed[i]].isNSFW;
            unchecked { ++i; ++count; }
        }
        return (listeds, points, isNFTList, isNSFWList);
    }

    function isListed(address token) public view returns (bool) {
        if (listed.length <= listedTokens[token].listedIndex) {
            return false;
        }
        return listed[listedTokens[token].listedIndex] == token;
    }

    function isApplicant(address token) public view returns (bool) {
        if (applicants.length <= applicationInfo[token].index) {
            return false;
        }
        return applicants[applicationInfo[token].index] == token;
    }

    function isReferrer(address ref) public view returns (bool) {
        if (ref == address(0)) {
            return false;
        }
        return refInfo[ref].cut > 0;
    }

    function getTotalEarned(address ref) external view returns (uint256) {
        return refInfo[ref].totalEarned;
    }

    function viewAllTokensReferred(address ref) external view returns (address[] memory) {
        return refInfo[ref].tokenReferrals;
    }

    function getNumberOfTokensReferred(address ref) external view returns (uint256) {
        return refInfo[ref].tokenReferrals.length;
    }

    receive() external payable {}
}