// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SafeTransfer {
    function _safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(
            _isContract(address(token)),
            "SafeTransfer: call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTransfer: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeTransfer: ERC20 operation did not succeed"
            );
        }
    }

    function _isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}


/* 
 * Made with <3 and public for free
 * @date    14-09-2021
 * @author  CoinTap Team
 * @website https://cointap.app
 * @email   contact@cointap.app
 */
contract CoinTapMultiSender is Context, Pausable, Ownable, SafeTransfer {
    // Cointap service address
    address public SERVICE_ADDRESS = 0xbe44ddE2875D023D8de11518b4b4e351d6A7bC58;
    uint256 public SERVICE_BASE_COST = 0 * 10**18;

    // Used to calculate fee if the number of tx is less than 5
    uint256 public MULTIPLIER_TRIAL = 1;

    // Used to calculate fee if the number of tx is less than 50 and more than 5
    uint256 public MULTIPLIER_PREMEUM = 10;

    // Extra fee for each transaction if the number of transfers is more than 50 (Excluding the first 50 transfers)
    uint256 public COST_PER_TX_DIAMOND = 0 * 10**18;

    uint256 public MAX_APPLY_FEE_PER_TX = 10000;

    address[] public managers;

    mapping(address => uint256) private discounts;

    constructor() {}

    function _estFeeTransferBulk(uint256 noOfTxs, address token)
        internal
        view
        returns (uint256)
    {
        uint256 totalFee;
        // if the number of transfer is more than {MAX_APPLY_FEE_PER_TX} then only apply fee for {MAX_APPLY_FEE_PER_TX} transfers
        if (noOfTxs >= MAX_APPLY_FEE_PER_TX) {
            noOfTxs = MAX_APPLY_FEE_PER_TX;
        }
        if (noOfTxs <= 5) {
            totalFee = SERVICE_BASE_COST * MULTIPLIER_TRIAL;
            return _feeAfterDiscount(totalFee, token);
        }
        if (noOfTxs <= 50) {
            totalFee = SERVICE_BASE_COST * MULTIPLIER_PREMEUM;
            return _feeAfterDiscount(totalFee, token);
        }
        totalFee =
            (SERVICE_BASE_COST * MULTIPLIER_PREMEUM) +
            (COST_PER_TX_DIAMOND * (noOfTxs - 50));
        return _feeAfterDiscount(totalFee, token);
    }

    function _sumTotal(uint256[] memory amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total = total + amounts[i];
        }
        return total;
    }

    // The same as the simple transfer function
    // But for multiple transfer instructions
    function transferBulk(
        address token,
        address[] memory _tos,
        uint256[] memory _values
    ) public payable virtual whenNotPaused returns (bool) {

        uint256 necessaryCost = _estFeeTransferBulk(_tos.length, token);
        require(
            msg.value >= necessaryCost,
            "MultiSend Bulk: Service cost too low"
        );

        // Transfer token amount from sender to MultiSender
        uint256 totalTokens = _sumTotal(_values);
        IERC20 erc20token = IERC20(token);

        _safeTransferFrom(erc20token, msg.sender, address(this), totalTokens);

        // Send token from MultiSender to recipients
        for (uint256 i = 0; i < _tos.length; i++) {
            // If one fails, revert the tx, including previous transfers
            _safeTransfer(erc20token, _tos[i], _values[i]);
        }

        payable(SERVICE_ADDRESS).transfer(msg.value);
        return true;
    }

    function transferBulkForReflection(
        address token,
        address[] memory _tos,
        uint256[] memory _values
    ) public payable virtual whenNotPaused returns (bool) {

        uint256 necessaryCost = _estFeeTransferBulk(_tos.length, token);
        require(
            msg.value >= necessaryCost,
            "MultiSend Bulk: Service cost too low"
        );

        // Transfer token amount from sender to MultiSender
        IERC20 erc20token = IERC20(token);

        // Send token from MultiSender to recipients
        for (uint256 i = 0; i < _tos.length; i++) {
            // If one fails, revert the tx, including previous transfers
            _safeTransferFrom(erc20token, msg.sender, _tos[i], _values[i]);
        }

        payable(SERVICE_ADDRESS).transfer(msg.value);
        return true;
    }

    function estFeeTransferBulk(uint256 noOfTxs, address token)
        external
        view
        returns (uint256)
    {
        return _estFeeTransferBulk(noOfTxs, token);
    }

    function setService(address newSerAdd)
        public
        virtual
        onlyManager
        returns (bool)
    {
        SERVICE_ADDRESS = newSerAdd;
        return true;
    }

    function setBaseCost(uint256 newBaseCost)
        public
        virtual
        onlyManager
        returns (bool)
    {
        SERVICE_BASE_COST = newBaseCost;
        return true;
    }

    function setMultilierTrial(uint256 newMul)
        public
        virtual
        onlyManager
        returns (bool)
    {
        MULTIPLIER_TRIAL = newMul;
        return true;
    }

    function setMultilierPremeum(uint256 newMul)
        public
        virtual
        onlyManager
        returns (bool)
    {
        MULTIPLIER_PREMEUM = newMul;
        return true;
    }

    function setCostPerTxForDiamond(uint256 newMul)
        public
        virtual
        onlyManager
        returns (bool)
    {
        COST_PER_TX_DIAMOND = newMul;
        return true;
    }

    function setMaxApplyFeePerTx(uint256 newMax)
        public
        virtual
        onlyManager
        returns (bool)
    {
        MAX_APPLY_FEE_PER_TX = newMax;
        return true;
    }

    // Manager functions
    function _isManager(address newManager) private view returns (bool) {
        for (uint8 i = 0; i < managers.length; i++) {
            if (managers[i] == newManager) {
                return true;
            }
        }
        return false;
    }

    function addManager(address newManager)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(
            !_isManager(newManager),
            "Manager: the address is already a manager"
        );
        managers.push(newManager);
        return true;
    }

    function removeManager(address manager)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(_isManager(manager), "Manager: the address isn't a manager");
        for (uint8 i = 0; i < managers.length; i++) {
            if (managers[i] == manager) {
                delete managers[i];
                break;
            }
        }
        return true;
    }

    modifier onlyManager() {
        require(
            owner() == _msgSender() || _isManager(_msgSender()),
            "Permission: caller is not the manager"
        );
        _;
    }

    // Handle discount for some special contracts
    /**
     * 1% => 100
     * 10% => 1000
     * 25,25% => 2525
     * 100% => 10000
     */
    function updateDiscountFor(address newContract, uint256 discountPercent)
        public
        virtual
        onlyManager
        returns (bool)
    {
        discounts[newContract] = discountPercent;
        return true;
    }

    function getDiscountPercent(address contractAddr)
        external
        view
        returns (uint256)
    {
        return discounts[contractAddr];
    }

    function _feeAfterDiscount(uint256 fee, address contractAddr)
        internal
        view
        returns (uint256)
    {
        return (fee * (10000 - discounts[contractAddr])) / 10000;
    }

    function estFeeAfterDiscount(uint256 fee, address contractAddr)
        external
        view
        returns (uint256)
    {
        return _feeAfterDiscount(fee, contractAddr);
    }

    function pause() public onlyManager whenNotPaused {
        _pause();
    }

    function unpause() public onlyManager whenPaused {
        _unpause();
    }
}
