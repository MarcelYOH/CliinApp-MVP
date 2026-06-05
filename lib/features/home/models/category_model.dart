// lib/features/home/models/category_model.dart

import 'package:flutter/material.dart';

class CategoryModel {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const CategoryModel({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
}