import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/wallet_remote_data_source.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_entity.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return WalletRepository(WalletRemoteDataSourceImpl(client));
});

class WalletState {
  final bool isLoading;
  final int selectedNominalCents;
  final TopupChannelEntity? selectedChannel;
  final List<TopupGroupEntity> channelGroups;
  final List<WalletMutationEntity> mutations;
  final String activeMutationFilter; // 'all', 'credit', 'debit'
  final TopupResultEntity? topupResult;
  final String? errorMessage;

  const WalletState({
    this.isLoading = false,
    this.selectedNominalCents = 5000000, // Rp 50.000 default
    this.selectedChannel,
    this.channelGroups = const [],
    this.mutations = const [],
    this.activeMutationFilter = 'all',
    this.topupResult,
    this.errorMessage,
  });

  WalletState copyWith({
    bool? isLoading,
    int? selectedNominalCents,
    TopupChannelEntity? selectedChannel,
    List<TopupGroupEntity>? channelGroups,
    List<WalletMutationEntity>? mutations,
    String? activeMutationFilter,
    TopupResultEntity? topupResult,
    String? errorMessage,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      selectedNominalCents: selectedNominalCents ?? this.selectedNominalCents,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      channelGroups: channelGroups ?? this.channelGroups,
      mutations: mutations ?? this.mutations,
      activeMutationFilter: activeMutationFilter ?? this.activeMutationFilter,
      topupResult: topupResult,
      errorMessage: errorMessage,
    );
  }
}

final walletNotifierProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repo);
});

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;

  WalletNotifier(this._repo) : super(const WalletState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    if (!AppConfig.isMockupEnabled) {
      state = state.copyWith(isLoading: true);
    }
    final channels = await _repo.getChannels();
    final mutations = await _repo.getMutations();

    TopupChannelEntity? defaultChannel;
    if (channels.isNotEmpty && channels.first.items.isNotEmpty) {
      defaultChannel = channels.first.items.first;
    }

    state = state.copyWith(
      isLoading: false,
      channelGroups: channels,
      selectedChannel: defaultChannel,
      mutations: mutations,
    );
  }

  void selectNominal(int cents) {
    state = state.copyWith(selectedNominalCents: cents);
  }

  void selectChannel(TopupChannelEntity channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  Future<void> fetchMutations({String? filter}) async {
    final type = filter ?? state.activeMutationFilter;
    state = state.copyWith(isLoading: true, activeMutationFilter: type);
    final list = await _repo.getMutations(type: type == 'all' ? null : type);
    state = state.copyWith(isLoading: false, mutations: list);
  }

  Future<TopupResultEntity?> proceedTopup() async {
    final channel = state.selectedChannel;
    if (channel == null) return null;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repo.requestTopup(
        amountCents: state.selectedNominalCents,
        method: channel.method,
        paymentGateway: channel.paymentGateway,
        channelCode: channel.code,
        channelName: channel.name,
      );
      state = state.copyWith(isLoading: false, topupResult: res);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

