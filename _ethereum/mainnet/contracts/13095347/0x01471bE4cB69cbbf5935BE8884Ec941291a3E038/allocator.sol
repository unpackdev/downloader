pragma solidity ^0.7.5;

//import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./IRNG.sol";




struct request {
    IERC721Enumerable     token;
    address[]             vaults;
    address               recipient;
    bytes32               requestHash;
    bool                  callback;
    bool                  collected;
}
contract allocator is Ownable {
    // see you later allocator....

    IRNG                          public rnd;
    string                        public sixties_reference = "https://www.youtube.com/watch?v=1Hb66FH9AzI";

    mapping(bytes32 => request)   public requestsFromHashes;
    mapping(bytes32 => uint256[]) public repliesFromHashes;
    mapping(address => bytes32[]) public userRequests;

    mapping (address => mapping(address => bool)) public canRequestThisVault; // can this source access these tokens
    mapping (address => bool)                     public auth;

    mapping (address => uint)                     public vaultRequests;

    bool                                                 inside;

    event ImmediateResolution(address requestor,IERC721Enumerable token,address vault,address recipient,uint256 tokenId);
    event RandomCardRequested(address requestor,IERC721Enumerable token,address vault,address recipient, bytes32 requestHash);
    event VaultControlChanged(address operator, address vault, bool allow);
    event OperatorSet(address operator, bool enabled);

    modifier onlyAuth() {
        require (auth[msg.sender] || (msg.sender == owner()),"unauthorised");
        _;
    }

    modifier noCallbacks() {
        require (!inside, "No rentrancy");
        inside = true;
        _;
        inside = false;
    }

    constructor(IRNG _rnd) {
        rnd = _rnd;
    }

    function getMeRandomCardsWithCallback(IERC721Enumerable token, address[] memory vaults, address recipient) external noCallbacks onlyAuth returns (bytes32) {
        return getMeRandomCards(token, vaults, recipient, true);
    }

    function getMeRandomCardsWithoutCallback(IERC721Enumerable token, address[] memory vaults, address recipient) external noCallbacks onlyAuth  returns (bytes32){
        return getMeRandomCards(token, vaults, recipient, false);
    }

    function getMeRandomCards(IERC721Enumerable token, address[] memory vaults, address recipient, bool withCallback ) internal returns (bytes32) {
        require(vaults.length <= 8,"Max 8 draws");
        bytes32 requestHash;
        if (withCallback) {
            requestHash = rnd.requestRandomNumberWithCallback();
        } else {
            requestHash = rnd.requestRandomNumber();
        }
        userRequests[recipient].push(requestHash);
        requestsFromHashes[requestHash] = request(
                token,
                vaults,
                recipient,
                requestHash,
                withCallback,
                false
            );
        for (uint j = 0; j < vaults.length; j++) {
            address vault = vaults[j];
            require(token.isApprovedForAll(vault, address(this)),"Vault does not allow token transfers");
            require(canRequestThisVault[msg.sender][vault],"Caller is not allowed to access this vault");
            uint256 supply = token.balanceOf(vault);
            require(vaultRequests[vault] < supply, "Not enough tokens to fulfill request");
            // This assumes that all the cards in this wallet are of the correct category
            vaultRequests[vault]++;
            emit RandomCardRequested(msg.sender,token,vault,recipient,requestHash);
        }
        return requestHash;
    }

    function process(uint256 random, bytes32 _requestId) external {
        require(msg.sender == address(rnd), "Unauthorised");
        my_process(random,_requestId);
    }

    function my_process(uint256 random, bytes32 _requestId) internal {
        request memory req = requestsFromHashes[_requestId];
        uint256[] storage replies = repliesFromHashes[_requestId];
        uint256 len = req.vaults.length;
        for (uint j = 0; j < len; j++) {
            uint randX = random & 0xffffffff;
            address vault = req.vaults[j];
            uint256 bal = req.token.balanceOf(vault);
            uint256 tokenId = req.token.tokenOfOwnerByIndex(vault, randX % bal);
            req.token.transferFrom(vault,req.recipient,tokenId);
            vaultRequests[vault]--;
            replies.push(tokenId);
            random = random >> 32;
        }
        requestsFromHashes[_requestId].collected=true;
    }

    function pickUpMyCards() external  {
        pickUpCardsFor(msg.sender);
    }

    function pickUpCardsFor(address recipient) public noCallbacks {
        uint256 len = userRequests[recipient].length;
        for (uint j = 0; j < len;j++) {
            bytes32 reqHash = userRequests[recipient][j]; 
            request memory req = requestsFromHashes[reqHash];
            if (!req.collected) {
                if (rnd.isRequestComplete(reqHash)) {
                    uint256 random  = rnd.randomNumber(reqHash);
                    my_process(random,reqHash);
                }
            }
        }
    }

    function numberOfRequests(address _owner) external view returns (uint256) {
        return userRequests[_owner].length;
    }

    
    function numberOfReplies(bytes32 _requestId) external view returns (uint256) {
        return repliesFromHashes[_requestId].length;
    }

    

    // ADMIN ------------------------

    function setAuth(address operator, bool enabled) external onlyAuth {
        auth[operator] = enabled;
        emit OperatorSet(operator, enabled);
    }

    // VAULTS ------------------------

    function setVaultAccess(address operator, address vault, bool allow) external onlyAuth {
        canRequestThisVault[operator][vault] = allow;
        emit VaultControlChanged(operator, vault, allow);
    }

    function checkAccess(IERC721Enumerable token, address vault) external view returns (bool) {
        return token.isApprovedForAll(vault, address(this));
    }

}