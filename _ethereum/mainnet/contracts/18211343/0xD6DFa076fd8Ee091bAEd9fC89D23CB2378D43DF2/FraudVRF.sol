// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀

 _____ ____      _   _   _ ______     ______  _____ 
 |  ___|  _ \    / \ | | | |  _ \ \   / /  _ \|  ___|
 | |_  | |_) |  / _ \| | | | | | \ \ / /| |_) | |_   
 |  _| |  _ <  / ___ \ |_| | |_| |\ V / |  _ <|  _|  
 |_|   |_| \_\/_/   \_\___/|____/  \_/  |_| \_\_|    

   Twitter: https://twitter.com/fraudeth_gg
   Telegram: http://t.me/fraudportal
   Website: https://fraudeth.gg
   Docs: https://docs.fraudeth.gg
*/                                                   
import "./ConfirmedOwner.sol";
import "./VRFV2WrapperConsumerBase.sol";
import "./IFraudToken.sol";
import "./IBribeToken.sol";
import "./ITaxHaven.sol";



contract FraudVRF is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
    IFraudToken public fraud;
    IBribeToken public bribe;
    ITaxHaven public taxHaven;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
        address user;
        uint256 vault;
        uint256 reward;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 2;

    // Address LINK 
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // address WRAPPER 
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    mapping(address => bool) public mainAdmins;
    mapping(address => bool) public admins;

    constructor(address _taxHaven, address _link, address _wraper, address _fraud, address _bribe)
        ConfirmedOwner(_taxHaven)
        VRFV2WrapperConsumerBase(_link, _wraper)
    {
        mainAdmins[msg.sender] = true;
        callbackGasLimit = 100000;
        taxHaven = ITaxHaven(_taxHaven);
        fraud = IFraudToken(_fraud);
        bribe = IBribeToken(_bribe);
    }

    function requestRandomWords(uint256 vault, uint256 reward, address user)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false,
            user: user,
            vault: vault,
            reward: reward
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        uint256 vault = s_requests[_requestId].vault;
        uint256 reward = s_requests[_requestId].reward;
        uint256 randNum = _randomWords[0] % 100;
        uint256 randNum2 = _randomWords[1] % 100;
        address user = s_requests[_requestId].user;

        if(vault == 0){
            // In Panama
            taxHaven.withdrawPanamaVrf(user, randNum);

        } else if(vault == 1){
            // In Venezuela
            taxHaven.withdrawVenezuelaVrf(user, randNum, randNum2);
        } else {
            // In ClaimBribe reward is reward
            taxHaven.claimBribeVrf(user, reward, randNum);
        }
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyAdmins {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) public onlyAdmins {
        callbackGasLimit = _callbackGasLimit;
    }

    function setAdmins(address _admin, bool _isAdmin) public onlyMainAdmins {
        admins[_admin] = _isAdmin;
    }

    modifier onlyMainAdmins() {
        require(mainAdmins[msg.sender], "Not a main admin");
        _;
    }

    modifier onlyAdmins(){
        require(mainAdmins[msg.sender] || admins[msg.sender], "Not an admin");
        _;
    }
}
