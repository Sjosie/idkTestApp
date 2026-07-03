// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSubscription = prefs.getBool('has_subscription') ?? false;
  runApp(MyApp(hasSubscription: hasSubscription));
}

class MyApp extends StatelessWidget {
  final bool hasSubscription;

  const MyApp({super.key, required this.hasSubscription});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionBloc(initialHasSubscription: hasSubscription),
      child: MaterialApp(
        title: 'Test Task App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: hasSubscription ? const MainScreen() : const OnboardingFlow(),
      ),
    );
  }
}

// -------------------- BLoC --------------------

enum SubscriptionType { month, year }

abstract class SubscriptionEvent {}

class BuySubscription extends SubscriptionEvent {
  final SubscriptionType type;
  BuySubscription(this.type);
}

class SubscriptionState {
  final bool hasSubscription;
  final SubscriptionType? type;

  const SubscriptionState({required this.hasSubscription, this.type});

  SubscriptionState copyWith({bool? hasSubscription, SubscriptionType? type}) {
    return SubscriptionState(
      hasSubscription: hasSubscription ?? this.hasSubscription,
      type: type ?? this.type,
    );
  }
}

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({required bool initialHasSubscription})
      : super(SubscriptionState(hasSubscription: initialHasSubscription)) {
    on<BuySubscription>(_onBuySubscription);
  }

  Future<void> _onBuySubscription(
    BuySubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_subscription', true);
    await prefs.setString('subscription_type', event.type.name);

    emit(state.copyWith(hasSubscription: true, type: event.type));
  }
}

// -------------------- Onboarding --------------------

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  void _next() {
    if (_pageIndex < 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: const [
                  _OnboardingPage(
                    title: 'Добро пожаловать',
                    description:
                        'Простое тестовое приложение с онбордингом и paywall.',
                  ),
                  _OnboardingPage(
                    title: 'Подписка',
                    description:
                        'Откройте доступ к контенту с помощью простой подписки.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Продолжить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;

  const _OnboardingPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// -------------------- Paywall --------------------

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SubscriptionBloc>();

    SubscriptionType selected = SubscriptionType.month;

    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          appBar: AppBar(title: const Text('Подписка')), 
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Откройте доступ ко всему контенту',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Выберите подходящий план подписки:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _PlanTile(
                  title: 'Месяц',
                  subtitle: 'Отмена в любое время',
                  price: '4,99 €',
                  isSelected: selected == SubscriptionType.month,
                  onTap: () => setState(() {
                    selected = SubscriptionType.month;
                  }),
                ),
                const SizedBox(height: 12),
                _PlanTile(
                  title: 'Год',
                  subtitle: 'Лучшая цена, скидка 40%',
                  price: '29,99 €',
                  isSelected: selected == SubscriptionType.year,
                  onTap: () => setState(() {
                    selected = SubscriptionType.year;
                  }),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      bloc.add(BuySubscription(selected));
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Продолжить'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Покупка эмулируется, реального биллинга нет.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            Text(
              price,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Main Screen --------------------

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Элемент контента #${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Простой текстовый контент для демонстрации главного экрана.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
