// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../utils/BEP20.sol';

// DYNAToken with Governance.
contract SeaToken is BEP20('Sea Token', 'SEA') {
    using SafeMath for uint256;
    uint256 public constant MAX_SUPPLY = 10000000 * 1e18; // 10M

    uint16 public transferTaxRate = 400;    // Transfer tax rate in basis points (default 4%)
    uint16 public burnRate = 20;            // 20% of transfer tax rate;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public marketingWalletAddress;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Addresses that excluded from transaction fee
    mapping(address => bool) private _excludedFromTransactionFee;

    // blacklist addresses
    mapping(address => bool) private _blocklistFromTransfer;

    uint16 public maxTransferAmountRate = 50; // .5 % of total supply

    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                !_excludedFromAntiWhale[sender]
                && !_excludedFromAntiWhale[recipient]
            ) {
                require(amount <= maxTransferAmount(), "SEA::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    constructor(address _holder) public {
        _mint(_holder, MAX_SUPPLY);

        marketingWalletAddress = msg.sender;

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
        _excludedFromAntiWhale[_holder] = true;

        _excludedFromTransactionFee[msg.sender] = true;
        _excludedFromTransactionFee[_holder] = true;
        
        _moveDelegates(address(0), _holder, MAX_SUPPLY);
    }

    function isExcludedFromAntiwhale(address _user) external view returns (bool) {
        return _excludedFromAntiWhale[_user];
    }

    function isExcludedFromTransactionFee(address _user) external view returns (bool) {
        return _excludedFromTransactionFee[_user];
    }

    function isBlacklistFromTransfer(address _user) external view returns (bool) {
        return _blocklistFromTransfer[_user];
    }

    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    function _transfer(address _sender, address _recepient, uint256 _amount) internal override antiWhale(_sender, _recepient, _amount) {
        require (!_blocklistFromTransfer[_sender] && !_blocklistFromTransfer[msg.sender], 'SEA::transfer blocked');

        if (_recepient == BURN_ADDRESS || transferTaxRate == 0 || _excludedFromTransactionFee[msg.sender]) {
            super._transfer(_sender, _recepient, _amount);
            _moveDelegates(_sender, _recepient, _amount);
        } else {
            uint256 taxAmount = _amount.mul(transferTaxRate).div(10000);
            uint256 burnAmount = taxAmount.mul(burnRate).div(100);
            uint256 marketingAmount = taxAmount.sub(burnAmount);
            uint256 sendAmount = _amount.sub(taxAmount);

            super._transfer(_sender, BURN_ADDRESS, burnAmount);
            _moveDelegates(_sender, BURN_ADDRESS, burnAmount);
            super._transfer(_sender, marketingWalletAddress, marketingAmount);
            _moveDelegates(_sender, marketingWalletAddress, marketingAmount);
            super._transfer(_sender, _recepient, sendAmount);
            _moveDelegates(_sender, _recepient, sendAmount);
        }
    }

    // update exclued address from anti whale. can be call by on the current operator
    function updateExcludedAddressFromAntiWhale(address _user, bool _isExcluded) external onlyOwner {
        _excludedFromAntiWhale[_user] = _isExcluded;
    }

    // update exclued address from tax fee. can be call by on the current operator
    function updateExcludedAddressFromTransactionFee(address _user, bool _isExcluded) external onlyOwner {
        _excludedFromTransactionFee[_user] = _isExcluded;
    }

    function updateMarketingWalletAddress(address _marketingWalletAddress) external onlyOwner {
        require(_marketingWalletAddress != address(0), "_marketingWalletAddress can not be zero address!");
      marketingWalletAddress = _marketingWalletAddress;
    }

    function updateBlocklistFromTransfer(address _user, bool _isBlocked) external onlyOwner {
      _blocklistFromTransfer[_user] = _isBlocked;
    }

    // pause tax fee strategy
    function pauseTaxStrategy() external onlyOwner {
        transferTaxRate = 0;
    }

    // unpause tax fee strategy
    function unpauseTaxStrategy() external onlyOwner {
        transferTaxRate = 400;
    }

    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "SEA::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying MARSs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "SEA::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOwner {
        require(_maxTransferAmountRate <= 10000, "SEA::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
