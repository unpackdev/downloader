//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Uncensorable is Ownable, ERC721 {

    // Constants

    // Minimum power (cost) to make a post.
    uint256 constant public MIN_POWER = 0.001 ether;

    // Percent of boost payment that is distributed to users.
    uint256 constant public BOOST_DISTRIBUTION_USERS_PERCENT = 80;

    // Percent of users cut that goes to post NFT holder. The remainder goes to boosters.
    uint256 constant public BOOST_DISTRIBUTION_HOLDERS_PERCENT = 20;


    // Global variables

    string private _metaBaseUri;

    struct PostAccount {
        uint256 power; // power contributed by account
        uint256 claimedPoints; // claimed disbursement points
    }
    struct PostData {
        uint256 totalPower; // total power
        uint256 totalPoints; // total disbursement points
        mapping (address => PostAccount) accounts; // balance details for each account
    }

    // Withdrawable balance per address.
    mapping (address => uint256) private balances;

    // Power and disbursement data for each post.
    mapping (uint256 => PostData) private posts;

    // Total unclaimed (due to rounding errors)
    uint256 private unclaimedAmount;

    // Next post token id.
    uint256 private nextId = 1;

    constructor(string memory metaBaseUri) ERC721("Uncensorable", "UC") {
        _metaBaseUri = metaBaseUri;
        _mint(msg.sender, 0);
    }

    // Events

    // Post is emitted exactly once per post, when it is created.
    event Post(uint256 indexed id, address indexed from, uint256 power);

    // Power is emitted every time a post is boosted.
    event Power(uint256 indexed id, address indexed from, uint256 power);

    // Withdraw is emitted when an account withdraws its available balance.
    event Withdraw(address indexed account, uint256 amount);

    // OpenZeppelin ERC721 overrides

    function _baseURI() internal view override returns (string memory) {
        return _metaBaseUri;
    }

    // Public functions

    // Read

    function minPower() public pure returns (uint256) {
        return MIN_POWER;
    }
    function boostDistributionUsersPercent() public pure returns (uint256) {
        return BOOST_DISTRIBUTION_USERS_PERCENT;
    }
    function boostDistributionHoldersPercent() public pure returns (uint256) {
        return BOOST_DISTRIBUTION_HOLDERS_PERCENT;
    }
    function powerOf(uint256 id) public view returns (uint256) {
        return posts[id].totalPower;
    }
    function unclaimed() public view returns (uint256){
        return unclaimedAmount;
    }
    function balance(address account) public view returns (uint256) {
        return balances[account];
    } 

    // Write

    function setMetaBaseUri(string calldata uri) external {
        _metaBaseUri = uri;
    }

    // post creates a new post (i.e., mints a new Uncensorable NFT) for the sender.
    // The payload must be a DEFLATE compressed protobuf with at least this specification:
    //
    // message Post {
    //     string message = 1;
    //     message Image {
    //         bytes bytes = 1;
    //         string content_type = 2;
    //     }
    //     Image image = 2;
    // }
    //
    // A client SHOULD ignore any post with a non-conforming payload.
    // See https://github.com/jcjlcodes/uncensorable-integration
    function post(bytes calldata payload) external payable {
        require(msg.value >= MIN_POWER, 'need minimum power payment to post');

        // 1. Mint the NFT.

        _mint(msg.sender, nextId);

        // 2. Send value to owner.

        balances[owner()] += msg.value;

        // 3. Add the power to the sender.

        addPower(nextId, msg.sender, msg.value);

        // 4. Emit the event and increase nextId.

        emit Post(nextId, msg.sender, msg.value);
        nextId++;
    }

    // boost adds power to the post on behalf of the sender.
    function boost(uint256 id) external payable {
        require(msg.value > 0, 'no payment supplied');
        
        // 1. Calculate shares.

        uint256 toUsers = percent(msg.value, BOOST_DISTRIBUTION_USERS_PERCENT);
        uint256 toOwner = msg.value - toUsers;
        uint256 toHolder = percent(toUsers, BOOST_DISTRIBUTION_HOLDERS_PERCENT);
        uint256 toBoosters = toUsers - toHolder;
        
        // 2. Give owners share.

        addToOwner(toOwner);

        // 3. Give NFT holders share, unless sender is NFT holder.

        address nftHolder = ownerOf(id);
        if (nftHolder == msg.sender) {
            addToOwner(toHolder);
        } else {
            balances[nftHolder] += toHolder;
        }

        // 4. Disburse dividends to boosters.

        disburse(id, msg.sender, toBoosters);

        // 5. Add the power to the NFT and emit the new power.

        addPower(id, msg.sender, msg.value);
        emit Power(id, msg.sender, powerOf(id));
    }

    // withdraw transfers the available balance to the sender.
    // Before transferring, the account is updated for the posts given by ids.
    // Determining which ids to update must be done off chain (reading the logs).
    // Returns the amount withdrawn, so withdraw can be used for prediction in a 
    // static call.
    function withdraw(uint256[] calldata ids) external returns(uint256) {
        for (uint256 i=0; i<ids.length; i++) {
            update(ids[i], msg.sender);
        }
        uint256 b = balances[msg.sender];
        balances[msg.sender] = 0;
        require(b > 0, 'no balance to withdraw');
        payable(msg.sender).transfer(b);
        emit Withdraw(msg.sender, b);
        return b;
    }

    // update claims dividends for an account and given post.
    function update(uint256 id, address account) public {
        uint256 b = owed(id, account);
        if (b > 0) {
            balances[account] += b;
            unclaimedAmount -= b;
        }
        posts[id].accounts[account].claimedPoints = posts[id].totalPoints;        
    }    

    // owed calculates how much dividends an account can claim for a given post.
    function owed(uint256 id, address account) public view returns(uint256) {
        uint256 newPoints = posts[id].totalPoints - posts[id].accounts[account].claimedPoints;
        if (newPoints == 0 || posts[id].accounts[account].power == 0) {
            return 0;
        }
        return pointsMul(newPoints, posts[id].accounts[account].power);
    }    


    // Internal functions

    // addToOwner adds balance to owner's account.
    function addToOwner(uint256 amount) internal {
        balances[owner()] += amount;
    }

    // addPower adds power to a post for an account.
    function addPower(uint256 id, address account, uint256 amount) internal {
        update(id, account);
        posts[id].totalPower += amount;
        posts[id].accounts[account].power += amount;
    }

    // disburse distributed amount as dividends to be claimed by all previous boosters for a post.
    function disburse(uint256 id, address account, uint256 amount) internal {
        uint256 powerExcludingAccount = posts[id].totalPower - posts[id].accounts[account].power;
        if (powerExcludingAccount == 0) {
            balances[owner()] += amount;
            return;
        }
        uint256 p = pointsDiv(amount, powerExcludingAccount);
        posts[id].totalPoints += p;
        posts[id].accounts[account].claimedPoints += p;
        unclaimedAmount += amount;
    }



    // Fixed point fraction calculations.

    uint256 constant pointsBits = 64;
    
    // percent computes p percent of x. (e.g. p=50, x=1 ether returns x=0.5 ether within precision).
    function percent(uint256 x, uint256 p) internal pure returns (uint256) {
        return (((x * p) << pointsBits) / 100) >> pointsBits;
    }

    // pointsDiv performes the division and keeps the result in fixed point format. 
    function pointsDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a << pointsBits) / b;
    }

    // pointsMul performs the multiplication and converts back to integer format.
    function pointsMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) >> pointsBits;
    }    
}