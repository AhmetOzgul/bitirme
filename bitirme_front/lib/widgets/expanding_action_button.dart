import 'package:flutter/material.dart';

class ExpandingActionButtonController {
  void Function()? close;
}

class ExpandingActionButton<T> extends StatefulWidget {
  static const _defaultSize = 48.0;
  static const _defaultIconColor = Colors.black;
  static const _defaultBackgroundColor = Colors.white;
  static const _animationDuration = Duration(milliseconds: 200);
  static const _shadowOpacity = 0.1;
  static const _shadowBlur = 4.0;
  static const _shadowOffset = Offset(0, 2);
  static const _iconScale = 0.6;
  static const _selectedIconScale = 0.7;
  static const _rotationAngle = 1.57;

  final T selectedValue;
  final List<({T value, IconData icon})> options;
  final Function(T) onChanged;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final ExpandingActionButtonController? controller;

  const ExpandingActionButton({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.size = _defaultSize,
    this.backgroundColor = _defaultBackgroundColor,
    this.iconColor = _defaultIconColor,
    this.controller,
  });

  @override
  State<ExpandingActionButton<T>> createState() =>
      ExpandingActionButtonState<T>();
}

class ExpandingActionButtonState<T> extends State<ExpandingActionButton<T>>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ExpandingActionButton._animationDuration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    widget.controller?.close = close;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final totalWidth = widget.size * (widget.options.length + 0.5);
      final maxWidth = MediaQuery.of(context).size.width * 0.8;
      final endWidth = totalWidth > maxWidth ? maxWidth : totalWidth;

      _widthAnimation = Tween<double>(
        begin: widget.size,
        end: endWidth,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _isInitialized = true;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void close() {
    if (_isExpanded) {
      _toggleExpanded();
    }
  }

  @override
  void dispose() {
    widget.controller?.close = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = widget.options.firstWhere(
      (option) => option.value == widget.selectedValue,
      orElse: () => widget.options.first,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.size,
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.size / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  ExpandingActionButton._shadowOpacity,
                ),
                blurRadius: ExpandingActionButton._shadowBlur,
                offset: ExpandingActionButton._shadowOffset,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isExpanded)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          constraints.maxWidth / widget.options.length;
                      return Row(
                        children:
                            widget.options.reversed.map((option) {
                              final isSelected =
                                  option.value == widget.selectedValue;
                              return Opacity(
                                opacity: _opacityAnimation.value,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      widget.onChanged(option.value);
                                      _toggleExpanded();
                                    },
                                    child: SizedBox(
                                      width: itemWidth,
                                      height: widget.size,
                                      child: Transform.rotate(
                                        angle:
                                            ExpandingActionButton
                                                ._rotationAngle,
                                        child: Icon(
                                          option.icon,
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : widget.iconColor,
                                          size:
                                              widget.size *
                                              ExpandingActionButton._iconScale,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ),
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    onTap: _toggleExpanded,
                    child: Transform.rotate(
                      angle: ExpandingActionButton._rotationAngle,
                      child: Icon(
                        selectedOption.icon,
                        color: widget.iconColor,
                        size:
                            widget.size *
                            ExpandingActionButton._selectedIconScale,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
