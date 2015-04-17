﻿// ------------------------------------------------------------------------------------------------------------------------------------------------------------
// <copyright file="AweSlider.cs" company="nGratis">
//  The MIT License (MIT)
//
//  Copyright (c) 2014 - 2015 Cahya Ong
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
// </copyright>
// <author>Cahya Ong - cahya.ong@gmail.com</author>
// <creation_timestamp>Friday, 17 April 2015 9:49:18 AM</creation_timestamp>
// ------------------------------------------------------------------------------------------------------------------------------------------------------------

namespace nGratis.Cop.Core.Wpf
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Windows;
    using System.Windows.Controls;
    using System.Windows.Controls.Primitives;

    public class AweSlider : Slider
    {
        public static readonly DependencyProperty StableValueProperty = DependencyProperty.Register(
            "StableValue",
            typeof(double),
            typeof(AweSlider),
            new PropertyMetadata(default(double), OnStableValueChanged));

        public static readonly DependencyProperty IsDraggingProperty = DependencyProperty.Register(
            "IsDragging",
            typeof(bool),
            typeof(AweSlider),
            new PropertyMetadata(default(bool)));

        public double StableValue
        {
            get { return (double)this.GetValue(StableValueProperty); }
            set { this.SetValue(StableValueProperty, value); }
        }

        public bool IsDragging
        {
            get { return (bool)this.GetValue(IsDraggingProperty); }
            private set { this.SetValue(IsDraggingProperty, value); }
        }

        protected override void OnThumbDragStarted(DragStartedEventArgs args)
        {
            base.OnThumbDragStarted(args);
            this.IsDragging = true;
        }

        protected override void OnThumbDragCompleted(DragCompletedEventArgs args)
        {
            this.StableValue = this.Value;
            this.IsDragging = false;
            base.OnThumbDragCompleted(args);
        }

        private static void OnStableValueChanged(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs args)
        {
            var slider = dependencyObject as AweSlider;
            var newValue = (double)args.NewValue;

            if (slider != null && !newValue.IsCloseTo(slider.Value))
            {
                slider.Value = newValue;
            }
        }
    }
}