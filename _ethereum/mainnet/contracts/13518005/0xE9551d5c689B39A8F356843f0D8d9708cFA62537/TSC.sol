// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./TerminateContractTemplate.sol";
import "./IExecute.sol";
import "./ITSCPool.sol";

contract TSC is TerminateContractTemplate {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    struct DepositERC20 {
        address tokens;
        uint256 value;
        string description;
        uint256 deposited;
    }

    struct TransferERC20 {
        address receiver;
        address tokens;
        uint256 value;
        string description;
        bool transfered;
    }

    struct DepositETH {
        uint256 value;
        string description;
        uint256 deposited;
    }

    struct TransferETH {
        address payable receiver;
        uint256 value;
        string description;
        bool transfered;
    }

    struct UploadSignature {
        address signer;
        bytes32 source; // sha256 of document
        string description;
        bytes signature;
    }

    struct ListDepositERC20 {
        mapping(uint256 => DepositERC20) list;
        uint256 size;
    }

    struct ListTransferERC20 {
        mapping(uint256 => TransferERC20) list;
        uint256 size;
    }

    struct ListDepositETH {
        mapping(uint256 => DepositETH) list;
        uint256 size;
    }

    struct ListTransferETH {
        mapping(uint256 => TransferETH) list;
        uint256 size;
    }

    struct ListUploadSignature {
        mapping(uint256 => UploadSignature) list;
        uint256 size;
    }

    struct DepositERC20Input {
        address tokens;
        uint256 value;
        string description;
    }

    struct TransferERC20Input {
        address receiver;
        address tokens;
        uint256 value;
        string description;
    }

    struct DepositETHInput {
        uint256 value;
        string description;
    }

    struct TransferETHInput {
        address payable receiver;
        uint256 value;
        string description;
    }

    struct UploadSignatureInput {
        address signer;
        bytes32 source; // sha256 of document
        string description;
    }

    struct BasicInfoInput {
        string title;
        uint256 timeout;
        uint256 deadline;
        address tokens_address_start;
        uint256 tokens_amount_start;
        address payable partner;
        string description;
        address payable execute_contract;
        address rewardToken;
        uint256 rewardValue;
    }

    struct Reward {
        address tokens;
        uint256 value;
    }

    struct StartTimingRequired {
        address tokens;
        uint256 value;
    }
    string public title;

    address payable public partner;

    uint256 public timeout;

    address payable public execute_contract;

    StartTimingRequired public startTimmingRequired;
    Reward public reward;

    ListDepositERC20 private listDepositERC20;
    ListTransferERC20 private listTransferERC20;
    ListDepositETH private listDepositETH;
    ListTransferETH private listTransferETH;
    ListUploadSignature private listUploadSignature;

    bool public ready;
    bool public isStartTimming;

    string public description;

    uint256 passCount;

    address public ownerPool;

    constructor(address _ownerPool) {
        ownerPool = _ownerPool;
    }

    event StartContract(uint256 timestamp);
    event StartTiming(uint256 timestamp);
    event SignatureUploaded(
        uint256 indexed _index,
        bytes32 _source,
        address _signers,
        bytes _signature,
        uint256 _timestamp
    );
    event DepositEthCompleted(
        uint256 indexed _index,
        uint256 _value,
        uint256 _timestamp
    );
    event DepositErc20Completed(
        uint256 indexed _index,
        address _tokens,
        uint256 _value,
        uint256 _timestamp
    );
    event TransferEthCompleted(
        uint256 indexed _index,
        address _receiver,
        uint256 _value,
        uint256 _timestamp
    );
    event TransferErc20Completed(
        uint256 indexed _index,
        address _receiver,
        address _tokens,
        uint256 _value,
        uint256 _timestamp
    );
    event ContractClosed(uint256 _timestamp, bool completed);

    modifier onlyPartner() {
        require(msg.sender == partner, "TSC: Only partner");
        _;
    }

    modifier onlyNotReady() {
        require(!ready, "TSC: Contract readied");
        _;
    }

    modifier onlyStartTimming() {
        require(isStartTimming, "TSC: Required start timming");
        _;
    }

    modifier onlyTokenOption(address _token) {
        require(
            ITSCPool(ownerPool).checkTokenOption(_token),
            "Token is not on the list options"
        );
        _;
    }

    function setExecuteContract(address payable _address)
        public
        onlyOwner
        onlyNotReady
        isLive
    {
        execute_contract = _address;
    }

    function setExpiration(uint256 _expiration)
        public
        virtual
        override
        onlyOwner
    {
        revert();
    }

    function setupAndStart(
        BasicInfoInput memory basicInfo,
        DepositERC20Input[] memory _depositErc20s,
        TransferERC20Input[] memory _transferErc20s,
        DepositETHInput[] memory _depositEths,
        TransferETHInput[] memory _transferEths,
        UploadSignatureInput[] memory _uploadSignatures
    ) external payable onlyOwner onlyNotReady isLive {
        _setupBasic(
            basicInfo.title,
            basicInfo.timeout,
            basicInfo.deadline,
            basicInfo.tokens_address_start,
            basicInfo.tokens_amount_start,
            basicInfo.partner,
            basicInfo.description,
            basicInfo.execute_contract,
            basicInfo.rewardToken,
            basicInfo.rewardValue
        );
        _setUpDepositErc20Functions(_depositErc20s);
        _setupTransferErc20Functions(_transferErc20s);
        _setupDepositEthFunctions(_depositEths);
        _setupTransferEthFunctions(_transferEths);
        _setupUploadSignatureFunctions(_uploadSignatures);
        start();
    }

    function _setupBasic(
        string memory _title,
        uint256 _timeout,
        uint256 _deadline,
        address _tokens_address_start,
        uint256 _tokens_amount_start,
        address payable _partner,
        string memory _description,
        address payable _execute_contract,
        address _rewardToken,
        uint256 _rewardValue
    ) private onlyTokenOption(_tokens_address_start) returns (bool) {
        require(_partner != address(0), "Partner address can not be zero!");
        require(
            _tokens_address_start != address(0),
            "Start token address can not be zero!"
        );
        title = _title;
        partner = _partner;
        description = _description;
        execute_contract = _execute_contract;

        timeout = _timeout;
        expiration = _deadline;
        startTimmingRequired = StartTimingRequired({
            tokens: _tokens_address_start,
            value: _tokens_amount_start
        });
        reward = Reward({tokens: _rewardToken, value: _rewardValue});
        return true;
    }

    function _setUpDepositErc20Functions(
        DepositERC20Input[] memory _depositErc20s
    ) private returns (bool) {
        for (uint256 i = 0; i < _depositErc20s.length; i++) {
            DepositERC20Input memory depositErc20Input = _depositErc20s[i];
            require(
                ITSCPool(ownerPool).checkTokenOption(depositErc20Input.tokens),
                "Token is not on the list options"
            );
            require(
                depositErc20Input.tokens != address(0x0),
                "TSC: ERC20 tokens address in Deposit ERC20 Function is required different 0x0"
            );
            require(
                depositErc20Input.value > 0,
                "TSC: value of ERC20 in Deposit ERC20 Function is required greater than 0"
            );
            listDepositERC20.list[i] = DepositERC20(
                depositErc20Input.tokens,
                depositErc20Input.value,
                depositErc20Input.description,
                0
            );
        }
        listDepositERC20.size = _depositErc20s.length;
        return true;
    }

    function _setupTransferErc20Functions(
        TransferERC20Input[] memory _transferErc20s
    ) private returns (bool) {
        for (uint256 i = 0; i < _transferErc20s.length; i++) {
            TransferERC20Input memory transferErc20Input = _transferErc20s[i];
            require(
                ITSCPool(ownerPool).checkTokenOption(transferErc20Input.tokens),
                "Token is not on the list options"
            );
            require(
                transferErc20Input.receiver != address(0x0),
                "TSC: receiver in  in Transfer Erc20 Function is required different 0x0"
            );
            require(
                transferErc20Input.tokens != address(0x0),
                "TSC: ERC20 tokens address in Transfer ERC20 Function is required different 0x0"
            );
            require(
                transferErc20Input.value > 0,
                "TSC: value of ETH in Transfer Erc20 Function is required greater than 0"
            );
            listTransferERC20.list[i] = TransferERC20(
                transferErc20Input.receiver,
                transferErc20Input.tokens,
                transferErc20Input.value,
                transferErc20Input.description,
                false
            );
        }
        listTransferERC20.size = _transferErc20s.length;
        return true;
    }

    function _setupDepositEthFunctions(DepositETHInput[] memory _depositEths)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < _depositEths.length; i++) {
            DepositETHInput memory deposit = _depositEths[i];
            require(
                deposit.value > 0,
                "TSC: value of ETH in Deposit ETH Function is required greater than 0"
            );
            listDepositETH.list[i] = DepositETH(
                deposit.value,
                deposit.description,
                0
            );
        }
        listDepositETH.size = _depositEths.length;
        return true;
    }

    function _setupTransferEthFunctions(TransferETHInput[] memory _transferEths)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < _transferEths.length; i++) {
            TransferETHInput memory transferEthInput = _transferEths[i];
            require(
                transferEthInput.receiver != address(0x0),
                "TSC: receiver in  in Transfer ETH Function is required different 0x0"
            );
            require(
                transferEthInput.value > 0,
                "TSC: value of ETH in Transfer ETH Function is required greater than 0"
            );
            listTransferETH.list[i] = TransferETH(
                transferEthInput.receiver,
                transferEthInput.value,
                transferEthInput.description,
                false
            );
        }
        listTransferETH.size = _transferEths.length;
        return true;
    }

    function _setupUploadSignatureFunctions(
        UploadSignatureInput[] memory _uploadSignatures
    ) private returns (bool) {
        for (uint256 i = 0; i < _uploadSignatures.length; i++) {
            UploadSignatureInput memory signature = _uploadSignatures[i];
            require(
                signature.signer != address(0x0),
                "TSC: signer in  in Upload Signature Function is required different 0x0"
            );
            listUploadSignature.list[i] = UploadSignature(
                signature.signer,
                signature.source,
                signature.description,
                ""
            );
        }
        listUploadSignature.size = _uploadSignatures.length;
        return true;
    }

    function start() public payable onlyOwner onlyNotReady isLive {
        require(
            startTimmingRequired.tokens != address(0x0),
            "TSC: Please setup ERC20 address to start"
        );
        require(timeout > 0, "TSC: Please setup time out");
        if (reward.tokens != address(0x0)) {
            IERC20(reward.tokens).safeTransferFrom(
                msg.sender,
                address(this),
                reward.value
            );
        } else {
            require(msg.value == reward.value, "TSC: Please add ETH reward");
        }
        ready = true;
        emit StartContract(block.timestamp);
    }

    function startTimming() external onlyPartner isLive {
        require(!isStartTimming, "TSC: Timming started");

        IERC20(startTimmingRequired.tokens).safeTransferFrom(
            msg.sender,
            address(this),
            startTimmingRequired.value
        );

        if (expiration > block.timestamp + timeout) {
            expiration = block.timestamp + timeout;
        }
        isStartTimming = true;
        emit StartTiming(block.timestamp);
    }

    function terminate() public override isOver onlyOwner {
        uint256 totalFunction = listDepositETH.size +
            listTransferETH.size +
            listDepositERC20.size +
            listTransferERC20.size +
            listUploadSignature.size;

        bool completed = totalFunction == passCount;
        emit ContractClosed(block.timestamp, completed);
        if (execute_contract != address(0)) {
            if (reward.tokens != address(0x0) && reward.value > 0) {
                IERC20(reward.tokens).safeTransfer(
                    execute_contract,
                    reward.value
                );
            }
            if (
                startTimmingRequired.tokens != address(0x0) &&
                startTimmingRequired.value > 0
            ) {
                IERC20(startTimmingRequired.tokens).safeTransfer(
                    execute_contract,
                    startTimmingRequired.value
                );
            }
            for (uint256 i = 0; i < listDepositERC20.size; i++) {
                if (
                    listDepositERC20.list[i].tokens != address(0x0) &&
                    listDepositERC20.list[i].value > 0
                ) {
                    IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                        execute_contract,
                        listDepositERC20.list[i].value
                    );
                }
            }
            Address.sendValue(execute_contract, address(this).balance);
            if (completed) {
                bool success = IExecute(execute_contract).execute();
                require(success, "TSC: Execution contract execute fail");
            } else {
                bool success = IExecute(execute_contract).revert();
                require(success, "TSC: Execution contract execute fail");
            }
        } else {
            if (completed) {
                _closeCompleted();
            } else {
                _closeNotCompleted();
            }
        }
        if (completed) {
            selfdestruct(payable(owner()));
        } else {
            selfdestruct(partner);
        }
    }

    function _closeCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).safeTransfer(partner, reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            Address.sendValue(partner, reward.value);
        }
        if (
            startTimmingRequired.tokens != address(0x0) &&
            startTimmingRequired.value > 0
        ) {
            IERC20(startTimmingRequired.tokens).safeTransfer(
                partner,
                startTimmingRequired.value
            );
        }

        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (
                listDepositERC20.list[i].tokens != address(0x0) &&
                listDepositERC20.list[i].value > 0
            ) {
                IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                    owner(),
                    listDepositERC20.list[i].value
                );
            }
        }
    }

    function _closeNotCompleted() private {
        if (reward.tokens != address(0x0) && reward.value > 0) {
            IERC20(reward.tokens).safeTransfer(owner(), reward.value);
        }
        if (reward.tokens == address(0x0) && reward.value > 0) {
            Address.sendValue(payable(owner()), reward.value);
        }
        if (
            startTimmingRequired.tokens != address(0x0) &&
            startTimmingRequired.value > 0
        ) {
            IERC20(startTimmingRequired.tokens).safeTransfer(
                owner(),
                startTimmingRequired.value
            );
        }

        for (uint256 i = 0; i < listDepositERC20.size; i++) {
            if (
                listDepositERC20.list[i].tokens != address(0x0) &&
                listDepositERC20.list[i].value > 0
            ) {
                IERC20(listDepositERC20.list[i].tokens).safeTransfer(
                    partner,
                    listDepositERC20.list[i].value
                );
            }
        }
    }

    function depositEth(uint256 _index)
        external
        payable
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            listDepositETH.list[_index].deposited <
                listDepositETH.list[_index].value,
            "TSC: Deposit over"
        );
        require(msg.value == listDepositETH.list[_index].value);
        listDepositETH.list[_index].deposited += msg.value;
        passCount++;
        emit DepositEthCompleted(
            _index,
            listDepositETH.list[_index].deposited,
            block.timestamp
        );
    }

    function transferEth(uint256 _index)
        external
        payable
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            !listTransferETH.list[_index].transfered,
            "TSC: Function is passed"
        );
        require(msg.value == listTransferETH.list[_index].value);
        listTransferETH.list[_index].transfered = true;
        passCount++;
        Address.sendValue(
            listTransferETH.list[_index].receiver,
            listTransferETH.list[_index].value
        );
        emit TransferEthCompleted(
            _index,
            listTransferETH.list[_index].receiver,
            listTransferETH.list[_index].value,
            block.timestamp
        );
    }

    function depositErc20(uint256 _index)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            listDepositERC20.list[_index].deposited <
                listDepositERC20.list[_index].value,
            "TSC: Function is passed"
        );
        uint256 preBalance = IERC20(listDepositERC20.list[_index].tokens)
            .balanceOf(address(this));

        IERC20(listDepositERC20.list[_index].tokens).safeTransferFrom(
            msg.sender,
            address(this),
            listDepositERC20.list[_index].value
        );

        listDepositERC20.list[_index].deposited =
            IERC20(listDepositERC20.list[_index].tokens).balanceOf(
                address(this)
            ) -
            preBalance;
        if (
            listDepositERC20.list[_index].deposited >=
            listDepositERC20.list[_index].value
        ) {
            passCount++;
            emit DepositErc20Completed(
                _index,
                listDepositERC20.list[_index].tokens,
                listDepositERC20.list[_index].value,
                block.timestamp
            );
        }
    }

    function transferErc20(uint256 _index)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            !listTransferERC20.list[_index].transfered,
            "TSC: Function is passed"
        );
        listTransferERC20.list[_index].transfered = true;
        passCount++;
        IERC20(listTransferERC20.list[_index].tokens).safeTransferFrom(
            msg.sender,
            listTransferERC20.list[_index].receiver,
            listTransferERC20.list[_index].value
        );
        emit TransferErc20Completed(
            _index,
            listTransferERC20.list[_index].receiver,
            listTransferERC20.list[_index].tokens,
            listTransferERC20.list[_index].value,
            block.timestamp
        );
    }

    function uploadSignature(uint256 _index, bytes memory _signature)
        external
        onlyPartner
        isLive
        onlyStartTimming
    {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );
        require(
            verify(
                listUploadSignature.list[_index].signer,
                listUploadSignature.list[_index].source,
                _signature
            )
        );
        listUploadSignature.list[_index].signature = _signature;
        passCount++;
        emit SignatureUploaded(
            _index,
            listUploadSignature.list[_index].source,
            listUploadSignature.list[_index].signer,
            _signature,
            block.timestamp
        );
    }

    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory _signature
    ) private pure returns (bool) {
        return _messageHash.recover(_signature) == _signer;
    }

    function isPassDepositErc20(uint256 _index) external view returns (bool) {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        return
            listDepositERC20.list[_index].value <=
            listDepositERC20.list[_index].deposited;
    }

    function isPassDepositEth(uint256 _index) external view returns (bool) {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );
        return
            listDepositETH.list[_index].value <=
            listDepositETH.list[_index].deposited;
    }

    function isPassTransferEth(uint256 _index) external view returns (bool) {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );
        return listTransferETH.list[_index].transfered;
    }

    function isPassTransferErc20(uint256 _index) external view returns (bool) {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );
        return listTransferERC20.list[_index].transfered;
    }

    function isPassSignature(uint256 _index) external view returns (bool) {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );
        return listUploadSignature.list[_index].signature.length > 0;
    }

    function listDepositEthSize() external view returns (uint256) {
        return listDepositETH.size;
    }

    function listDepositErc20Size() external view returns (uint256) {
        return listDepositERC20.size;
    }

    function listTransferEthSize() external view returns (uint256) {
        return listTransferETH.size;
    }

    function listTransferErc20Size() external view returns (uint256) {
        return listTransferERC20.size;
    }

    function listUploadSignatureSize() external view returns (uint256) {
        return listUploadSignature.size;
    }

    function depositEthFunction(uint256 _index)
        external
        view
        returns (
            uint256 _value,
            string memory _description,
            uint256 _deposited
        )
    {
        require(
            listDepositETH.size > _index,
            "TSC: Invalid required functions"
        );

        _value = listDepositETH.list[_index].value;
        _description = listDepositETH.list[_index].description;
        _deposited = listDepositETH.list[_index].deposited;
    }

    function depositErc20Function(uint256 _index)
        external
        view
        returns (
            address _tokens,
            uint256 _value,
            string memory _symbol,
            string memory _description,
            uint256 _deposited
        )
    {
        require(
            listDepositERC20.size > _index,
            "TSC: Invalid required functions"
        );
        _tokens = listDepositERC20.list[_index].tokens;
        _value = listDepositERC20.list[_index].value;
        _description = listDepositERC20.list[_index].description;
        _deposited = listDepositERC20.list[_index].deposited;
        if (_tokens != address(0x0)) {
            _symbol = ERC20(_tokens).symbol();
        }
    }

    function transferEthFunction(uint256 _index)
        external
        view
        returns (
            address _receiver,
            uint256 _value,
            string memory _description,
            bool _transfered
        )
    {
        require(
            listTransferETH.size > _index,
            "TSC: Invalid required functions"
        );

        _receiver = listTransferETH.list[_index].receiver;
        _value = listTransferETH.list[_index].value;
        _description = listTransferETH.list[_index].description;
        _transfered = listTransferETH.list[_index].transfered;
    }

    function transferErc20Function(uint256 _index)
        external
        view
        returns (
            address _receiver,
            address _token,
            uint256 _value,
            string memory _description,
            bool _transfered
        )
    {
        require(
            listTransferERC20.size > _index,
            "TSC: Invalid required functions"
        );

        _receiver = listTransferERC20.list[_index].receiver;
        _token = listTransferERC20.list[_index].tokens;
        _value = listTransferERC20.list[_index].value;
        _description = listTransferERC20.list[_index].description;
        _transfered = listTransferERC20.list[_index].transfered;
    }

    function uploadSignatureFunction(uint256 _index)
        external
        view
        returns (
            address _signer,
            bytes32 _source,
            string memory _description,
            bytes memory _signature
        )
    {
        require(
            listUploadSignature.size > _index,
            "TSC: Invalid required functions"
        );

        _signer = listUploadSignature.list[_index].signer;
        _source = listUploadSignature.list[_index].source;
        _description = listUploadSignature.list[_index].description;
        _signature = listUploadSignature.list[_index].signature;
    }
}
